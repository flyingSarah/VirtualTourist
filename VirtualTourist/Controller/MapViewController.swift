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
    
    //MARK --- Useful Variables
    
    //MARK --- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //set the map view delegate
        mapView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        FlickrClient.sharedInstance().getPhotos(36.0, longitude: -115.0) { result, error in
            
            if let error = error
            {
                print("error getting photos from lat/lon:\n  \(error.code)\n  \(error.localizedDescription)")
            }
            else
            {
                let firstImageURL = FlickrClient.sharedInstance().photos.first?.valueForKey(FlickrClient.JSONResponseKeys.TITLE)
                
                print("sucessfully got photos! first url is: \(firstImageURL)")
            }
        }
    }
    
    //MARK --- Map Behavior
    
    //MARK --- Map View Delegate
    
    /*func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        
    }*/

    //MARK --- Core Data
    
    //MARK --- Helpers
}
