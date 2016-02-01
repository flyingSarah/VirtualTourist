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
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var noPhotosFound: UIImageView!
    
    //MARK --- Useful Variables
    
    var thisPin: Pin!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected".
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    //MARK --- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapView.userInteractionEnabled = false
        
        collectionView.delegate = self
        collectionView.dataSource = self
        fetchedResultsController.delegate = self
        
        //annotation for map view and zoom in
        let lat = CLLocationDegrees(thisPin.location!.latitude)
        let long = CLLocationDegrees(thisPin.location!.longitude)
        let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates

        mapView.addAnnotation(annotation)
        mapView.setRegion(MKCoordinateRegionMakeWithDistance(coordinates, 20000, 20000), animated: false)
        
        //perform the fetch for the core data we need to access
        do
        {
            try self.fetchedResultsController.performFetch()
        }
        catch
        {
            NSLog("could not perform fetch: \(error)")
        }
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        noPhotosFound.hidden = true
        
        if(!thisPin.location!.alreadyGotPhotos)
        {
            print("this pin doesn't already have its photos")
            findPhotos(thisPin.location!)
        }
        else
        {
            print("this pin already has its photos")
        }
    }
    
    //MARK --- Refresh and/or Delete Behavior
    
    @IBAction func bottomButtonTriggered(sender: UIBarButtonItem)
    {
        if(sender.title == "New Collection")
        {
            getNewCollection()
        }
    }
    
    func getNewCollection()
    {
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects
        {
            for object in fetchedObjects
            {
                let photo = object as! Photo
                self.sharedContext.deleteObject(photo)
            }
            CoreDataStackManager.sharedInstance().saveContext()
            print("delete the objects")
        }
        else
        {
            print("no fetched objects")
        }
        
        findPhotos(thisPin.location!)
    }
    
    //MARK --- Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "uniqueId", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.thisPin.location!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    //MARK --- Fetched Results Controller Delegate Methods
    
    //I learned how to adapt the collection view for these methods from this stack overflow topic: http://stackoverflow.com/questions/20554137/nsfetchedresultscontollerdelegate-for-collectionview
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("the fetched results will change the content")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        collectionView.performBatchUpdates({ () -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
        }, completion: nil)
    }
    
    //MARK --- Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        let cellCount = self.fetchedResultsController.sections![section].numberOfObjects
        //print("cell count in collection view: \(cellCount)")

        return cellCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoViewCell
        cell.activityIndicator.hidesWhenStopped = true
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: PhotoViewCell, atIndexPath indexPath: NSIndexPath)
    {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let image = photo.photoImage
        {
            if(indexPath.item < 2)
            {
                print("cell \(indexPath.item) already had the photo")
            }
            photo.loadUpdateHandler = nil
            self.noPhotosFound.hidden = true
            cell.imageView.image = image
            cell.activityIndicator.stopAnimating()
        }
        else
        {
            noPhotosFound.hidden = true
            
            photo.loadUpdateHandler = nil
            cell.imageView.image = UIImage(named: "photoDownloading")
            cell.activityIndicator.startAnimating()
            
            if let imageURL = NSURL(string: photo.url_m)
            {
                FlickrClient.sharedInstance().downloadImage(imageURL) { data, error in
                    
                    if let error = error
                    {
                        print("error downloading photos from imageURL: \(imageURL) \(error.localizedDescription)")
                        dispatch_async(dispatch_get_main_queue()) {
                            photo.loadUpdateHandler = nil
                            cell.imageView.image = UIImage(named: "photoNotFound")
                            cell.activityIndicator.stopAnimating()
                        }
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            if let photoImage = UIImage(data: data!)
                            {
                                photo.loadUpdateHandler = { [unowned self] () -> Void in
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.collectionView.reloadItemsAtIndexPaths([indexPath])
                                    })
                                }
                                photo.photoImage = photoImage
                            }
                            else
                            {
                                photo.loadUpdateHandler = nil
                                cell.imageView.image = UIImage(named: "photoNotFound")
                                cell.activityIndicator.stopAnimating()
                            }
                        }
                    }
                }
            }
            else
            {
                print("Couldn't make an NSURL from photo.url_m string in configure cell.")
                cell.imageView.image = UIImage(named: "photoNotFound")
                cell.activityIndicator.stopAnimating()
            }
        }
    }
    
    //MARK --- Photo Client Stuff
    
    func findPhotos(pin: Location)
    {
        pin.alreadyGotPhotos = true
        
        //find the photos for the selected latitude and longitude
        FlickrClient.sharedInstance().getPhotos(pin) { result, error in
            
            if let error = error
            {
                print("error getting photos from lat/lon:\n  \(error.code)\n  \(error.localizedDescription)")
                dispatch_async(dispatch_get_main_queue()) {
                    self.noPhotosFound.hidden = false
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue()) {
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
    }
}