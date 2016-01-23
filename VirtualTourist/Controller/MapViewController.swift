//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Sarah Howe on 12/3/15.
//  Copyright © 2015 SarahHowe. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    //MARK --- Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteModeButton: UIBarButtonItem!
    @IBOutlet weak var deleteLabel: UILabel!
    
    //MARK --- Useful Variables
    
    var longPressRecognizer: UILongPressGestureRecognizer? = nil
    
    var currentPin: Location? = nil
    
    var deleteModeEnabled = false
    var didDragPin = false
    
    //MARK --- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //set the map view delegate
        mapView.delegate = self
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("pinDrop:"))
        longPressRecognizer?.minimumPressDuration = 0.5
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        addPinDropRecognizer()
        
        //add the pin annotations to the map by fetching the saved locations
        let pins = fetchLocations()
        
        if(!pins.isEmpty)
        {
            for pin in pins
            {
                mapView.addAnnotation(pin)
            }
        }
    }
    
    //MARK --- Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //MARK --- Button Behavior
    
    @IBAction func deleteButtonPressed(sender: AnyObject)
    {
        //TODO: might want to check to see if there are any pins first before entering delete mode
        
        if(deleteModeEnabled)
        {
            deleteModeEnabled = false
            deleteModeButton.title = "Delete"
            deleteLabel.hidden = true
            addPinDropRecognizer()
            
            //TODO: update context if pins change
        }
        else
        {
            deleteModeEnabled = true
            deleteModeButton.title = "Done"
            deleteLabel.hidden = false
            removePinDropRecognizer()
        }
    }
    
    
    //MARK --- Map Behavior
    
    func fetchLocations() -> [Location]
    {
        let fetchRequest = NSFetchRequest(entityName: "Location")
        
        //get all of the locations
        do
        {
            let fetchedLocations = try sharedContext.executeFetchRequest(fetchRequest) as! [Location]
            return fetchedLocations
        }
        catch
        {
            return [Location]()
        }
    }
    
    func addPinDropRecognizer()
    {
        view.addGestureRecognizer(longPressRecognizer!)
    }
    
    func removePinDropRecognizer()
    {
        view.removeGestureRecognizer(longPressRecognizer!)
    }
    
    func pinDrop(recognizer: UILongPressGestureRecognizer)
    {
        //I learned how to get the pins location and allow dragging right when it's dropped from this thread on the forums: https://discussions.udacity.com/t/how-can-i-make-a-new-pin-draggable-right-after-adding-it/26653
        let longPressLocation: CGPoint = recognizer.locationInView(mapView)
        let pinLocation = mapView.convertPoint(longPressLocation, toCoordinateFromView: mapView)
        
        //depending on the state of the gesture, add or select a pin, move it, or save the context
        if(recognizer.state == UIGestureRecognizerState.Began)
        {
            currentPin = Location(latitude: pinLocation.latitude, longitude: pinLocation.longitude, context: sharedContext)
            
            print("add new pin at latitude: \(pinLocation.latitude) longitude: \(pinLocation.longitude)")
            
            mapView.addAnnotation(currentPin!)
        }
        else if(recognizer.state == UIGestureRecognizerState.Ended)
        {
            //save context now that new pins have been added
            CoreDataStackManager.sharedInstance().saveContext()
            
            //pre-fetch photo
            //findPhotos(currentPin!)
        }
    }
    
    /*func findPhotos(pin: Location)
    {
        if(pin.isGettingPhotos)
        {
            return
        }
        else
        {
            pin.isGettingPhotos = true
        }
        
        //find the photos for the selected latitude and longitude
        FlickrClient.sharedInstance().getPhotos(pin) { result, error in
            
            if let error = error
            {
                print("error getting photos from lat/lon:\n  \(error.code)\n  \(error.localizedDescription)")
            }
            else
            {
                dispatch_async(dispatch_get_main_queue()) {
                    
                    print("saved context after getting photos from map view")
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
                pin.isGettingPhotos = false
            }
        }
    }*/
    
    //MARK --- Map View Delegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        //this makes it so you can delete the annotation even if it was already the selected annotation
        mapView.deselectAnnotation(view.annotation, animated: false)
        view.setSelected(true, animated: false)
        
        currentPin = view.annotation as? Location
        
        if(deleteModeEnabled)
        {
            //delete the pin if we are in edit mode
            mapView.removeAnnotation(view.annotation!)
            sharedContext.deleteObject(currentPin!)
            CoreDataStackManager.sharedInstance().saveContext()
        }
        else
        {
            if(didDragPin)
            {
                didDragPin = false
                CoreDataStackManager.sharedInstance().saveContext()
            }
            else
            {
                print("go to the selected annotation view at latitude : \(view.annotation?.coordinate.latitude) longitude: \(view.annotation?.coordinate.longitude)")
                
                //set the current pin as the pin that the photo controller will use
                let photoController = storyboard!.instantiateViewControllerWithIdentifier("PhotoViewController") as! PhotoViewController
                
                photoController.thisPin = currentPin
                
                //set the back item to say "OK" instead of "Virtual Tourist"
                //learned how to do this from this stackoverflow topic: http://stackoverflow.com/questions/9871578/how-to-change-the-uinavigationcontroller-back-button-name
                let backItem = UIBarButtonItem(title: "OK", style: .Plain, target: nil, action: nil)
                navigationItem.backBarButtonItem = backItem
                
                //go to the photo view controller
                navigationController!.pushViewController(photoController, animated: true)
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
        
        if(pinView == nil)
        {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
        }
        else
        {
            pinView!.annotation = annotation
        }
        
        pinView?.draggable = true
        
        //to drag the pin it must be selected
        pinView?.setSelected(true, animated: false)
        
        return pinView
    }
    
    
    //learned about this function from this stackoverflow page: http://stackoverflow.com/questions/29776853/ios-swift-mapkit-making-an-annotation-draggable-by-the-user
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState)
    {
        switch (newState)
        {
        case .Ending, .Canceling:
            didDragPin = true
        default: break
        }
    }
}
