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
    
    var currentPin = Pin()
    
    var deleteModeEnabled = false
    var didDragPin = false
    
    //MARK --- Keys for UserDefaults
    struct Keys
    {
        static let AppHasBeenLaunchedBefore = "appHasBeenLaunchedBefore"
        static let LatitudeDelta = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
        static let CenterLatitude = "centerLatitude"
        static let CenterLongitude = "centerLongitude"
    }
    
    //MARK --- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //set the map view delegate
        mapView.delegate = self
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("pinDrop:"))
        longPressRecognizer?.minimumPressDuration = 0.5
        
        //check to see if the app has been launched before, if so, load the user defaults for the map region
        let appHasBeenLaunchedBefore = NSUserDefaults.standardUserDefaults().boolForKey(Keys.AppHasBeenLaunchedBefore)
        
        if(appHasBeenLaunchedBefore)
        {
            //Retreive the Map Region from the NSUserDefaults
            let latitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey(Keys.LatitudeDelta) as CLLocationDegrees
            let longitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey(Keys.LongitudeDelta) as CLLocationDegrees
            let coordinateSpan = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let centerLatitude = NSUserDefaults.standardUserDefaults().doubleForKey(Keys.CenterLatitude) as CLLocationDegrees
            let centerLongitude = NSUserDefaults.standardUserDefaults().doubleForKey(Keys.CenterLongitude) as CLLocationDegrees
            let centerLocation = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
            
            mapView.setRegion(MKCoordinateRegion(center: centerLocation, span: coordinateSpan), animated: false)
        }
        else
        {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: Keys.AppHasBeenLaunchedBefore)
        }
        
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
                let lat = pin.latitude
                let long = pin.longitude
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                let annotation = Pin()
                annotation.coordinate = coordinate
                annotation.location = pin
                print("added annotation on view change at lat: \(annotation.coordinate.latitude) long: \(annotation.coordinate.longitude)")
                mapView.addAnnotation(annotation)
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
            currentPin.location = Location(latitude: pinLocation.latitude, longitude: pinLocation.longitude, context: sharedContext)
            
            let lat = pinLocation.latitude
            let long = pinLocation.longitude
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            currentPin.coordinate = coordinate
            
            print("add new pin at latitude: \(pinLocation.latitude) longitude: \(pinLocation.longitude)")
            
            mapView.addAnnotation(currentPin)
        }
        else if(recognizer.state == UIGestureRecognizerState.Ended)
        {
            //save context now that new pins have been added
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    //MARK --- Map View Delegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        //this makes it so you can delete the annotation even if it was already the selected annotation
        mapView.deselectAnnotation(view.annotation, animated: false)
        view.setSelected(true, animated: false)
        
        if let annotation = view.annotation as? Pin
        {
            currentPin = annotation
            
            if(deleteModeEnabled)
            {
                //delete the pin if we are in edit mode
                mapView.removeAnnotation(annotation)
                sharedContext.deleteObject(currentPin.location!)
                CoreDataStackManager.sharedInstance().saveContext()
            }
            else
            {
                if(didDragPin)
                {
                    didDragPin = false
                    print("move pin to latitude: \(currentPin.coordinate.latitude) longitude: \(currentPin.coordinate.longitude)")
                    
                    sharedContext.deleteObject(currentPin.location!)
                    
                    currentPin.location = Location(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: sharedContext)
                    
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
        else
        {
            print("couldn't use the Pin class as the view annotation")
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
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        //save map region to the user defaults whenever it changes
        let latitudeDelta = mapView.region.span.latitudeDelta as Double
        let longitudeDelta = mapView.region.span.longitudeDelta as Double
        let centerLatitude = mapView.region.center.latitude as Double
        let centerLongitude = mapView.region.center.longitude as Double
        
        NSUserDefaults.standardUserDefaults().setDouble(latitudeDelta, forKey: Keys.LatitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(longitudeDelta, forKey: Keys.LongitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(centerLatitude, forKey: Keys.CenterLatitude)
        NSUserDefaults.standardUserDefaults().setDouble(centerLongitude, forKey: Keys.CenterLongitude)
        
        print("saved map region to user defaults")
    }
}
