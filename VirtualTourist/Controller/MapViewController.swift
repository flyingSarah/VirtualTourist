//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Sarah Howe on 12/3/15.
//  Copyright © 2015 SarahHowe. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    //MARK --- Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteModeButton: UIBarButtonItem!
    @IBOutlet weak var deleteLabel: UILabel!
    
    //MARK --- Useful Variables
    
    var longPressRecognizer: UILongPressGestureRecognizer? = nil
    var currentAnnotation: MKPointAnnotation? = nil
    var deleteModeEnabled = false
    
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
        
        FlickrClient.sharedInstance().getPhotos(36.0, longitude: -115.0) { result, error in
            
            if let error = error
            {
                print("error getting photos from lat/lon:\n  \(error.code)\n  \(error.localizedDescription)")
            }
            else
            {
                let firstImageURL = FlickrClient.sharedInstance().photos.first?.valueForKey(FlickrClient.JSONResponseKeys.PHOTO_URL)
                
                print("sucessfully got photos! first url is: \(firstImageURL!)")
            }
        }
    }
    
    //MARK --- Core Data
    
    
    //MARK --- Button Behavior
    
    @IBAction func deleteButtonPressed(sender: AnyObject)
    {
        if(deleteModeEnabled)
        {
            deleteModeEnabled = false
            deleteModeButton.title = "Delete"
            deleteLabel.hidden = true
            
            //update context if pins change
        }
        else
        {
            deleteModeEnabled = true
            deleteModeButton.title = "Done"
            deleteLabel.hidden = false
        }
    }
    
    
    //MARK --- Map Behavior
    
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
        //I learned how to get the pins location from this thread on the forums: https://discussions.udacity.com/t/how-can-i-make-a-new-pin-draggable-right-after-adding-it/26653
        let longPressLocation: CGPoint = recognizer.locationInView(mapView)
        let pinLocation = mapView.convertPoint(longPressLocation, toCoordinateFromView: mapView)
        
        //depending on the state of the gesture, add or select a pin, move it, or save the context
        if(recognizer.state == UIGestureRecognizerState.Began)
        {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pinLocation
            currentAnnotation = annotation
            
            print("add new pin at latitude: \(pinLocation.latitude) longitude: \(pinLocation.longitude)")
            
            mapView.addAnnotation(annotation)
        }
        else if(recognizer.state == UIGestureRecognizerState.Changed)
        {
            print("updated current pin - latitude: \(pinLocation.latitude) longitude: \(pinLocation.longitude)")
                
            currentAnnotation?.coordinate = pinLocation
        }
        else if(recognizer.state == UIGestureRecognizerState.Ended)
        {
            //save context
        }
    }
    
    //MARK --- Map View Delegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        //this makes it so you can delete the annotation even if it was already the selected annotation
        mapView.deselectAnnotation(view.annotation, animated: false)
        view.setSelected(true, animated: false)
        
        if(deleteModeEnabled)
        {
            //delete the pin if we are in edit mode
            mapView.removeAnnotation(view.annotation!)
            print("delete the selected annotation at latitude: \(view.annotation?.coordinate.latitude) longitude: \(view.annotation?.coordinate.longitude)")
        }
        else
        {
            //TODO: make it so you can drag the pin anywhere else??
            //currentAnnotation = view.annotation
            print("go to the selected annotation view at latitude : \(view.annotation?.coordinate.latitude) longitude: \(view.annotation?.coordinate.longitude)")
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
            print("done dragging")
        default: break
        }
    }
    
    //MARK --- Helpers
}
