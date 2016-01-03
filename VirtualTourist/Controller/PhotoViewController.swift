//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Sarah Howe on 1/2/16.
//  Copyright © 2016 SarahHowe. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    //MARK --- Outlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK --- Useful Variables
    
    var thisPin: Location!
    
    //MARK --- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapView.userInteractionEnabled = false
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //fetch the data we need
        do
        {
            try fetchedResultsController.performFetch()
        }
        catch {}
        
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if(thisPin.photos.isEmpty)
        {
            findPhotos(thisPin.latitude, longitude: thisPin.longitude)
        }
    }
    
    //MARK --- Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.thisPin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    //MARK --- Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        
        return fetchedResultsController.sections![section].numberOfObjects
        //return thisPin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoViewCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        
        print("cell for item at index path \(photo.url_m)")
        //pass each memed image to each cell
        //let meme = memes[indexPath.item]
        //let thisImage = meme.memedImage
        //cell.setNewMemedImage(thisImage)
        
        return cell
    }
    
    //MARK --- Photo Client Stuff
    
    func findPhotos(latitude: Double, longitude: Double)
    {
        //find the photos for the selected latitude and longitude
        FlickrClient.sharedInstance().getPhotos(latitude, longitude: longitude) { result, error in
            
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
}