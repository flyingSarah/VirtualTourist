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
    
    //MARK --- Useful Variables
    
    var thisPin: Location!
    
    var blockOperations: [NSBlockOperation] = []
    
    //var photosAreReady: Bool? = nil
    
    //MARK --- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapView.userInteractionEnabled = false
        
        collectionView.delegate = self
        collectionView.dataSource = self
        fetchedResultsController.delegate = self
        
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
        
        if(thisPin.photos.isEmpty)
        {
            findPhotos(thisPin)
        }
        else
        {
            print("the photos array wasn't empty")
        }
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        //cancel all block operations when the view controller is exited
        for operation: NSBlockOperation in blockOperations
        {
            operation.cancel()
        }
        blockOperations.removeAll(keepCapacity: false)
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
        
        findPhotos(thisPin)
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
    
    //MARK --- Fetched Results Controller Delegate Methods
    
    //I learned how to adapt the collection view for these methods from this stack overflow topic: http://stackoverflow.com/questions/20554137/nsfetchedresultscontollerdelegate-for-collectionview
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        blockOperations.removeAll(keepCapacity: false)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
    {
        switch type {
        case .Insert:
            blockOperations.append(NSBlockOperation(block: { [weak self] in
                
                if let this = self
                {
                    this.collectionView.insertSections(NSIndexSet(index: sectionIndex))
                }}))
        case .Delete:
            blockOperations.append(NSBlockOperation(block: { [weak self] in
                
                if let this = self
                {
                    this.collectionView.deleteSections(NSIndexSet(index: sectionIndex))
                }}))
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type {
        case .Insert:
            blockOperations.append(NSBlockOperation(block: { [weak self] in
                
                if let this = self
                {
                    this.collectionView.insertItemsAtIndexPaths([newIndexPath!])
                }}))
        case .Delete:
            blockOperations.append(NSBlockOperation(block: { [weak self] in
                
                if let this = self
                {
                    this.collectionView.deleteItemsAtIndexPaths([indexPath!])
                }}))
        case .Update:
            blockOperations.append(NSBlockOperation(block: { [weak self] in
                
                if let this = self
                {
                    this.collectionView.reloadItemsAtIndexPaths([indexPath!])
                }}))
        case .Move:
            blockOperations.append(NSBlockOperation(block: { [weak self] in
                
                if let this = self
                {
                    this.collectionView.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                }}))
        }
        
        /*dispatch_async(dispatch_get_main_queue()) {
            
            CoreDataStackManager.sharedInstance().saveContext()
        }*/
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        collectionView.performBatchUpdates({ () -> Void in
            
            for operation: NSBlockOperation in self.blockOperations
            {
                operation.start()
            }},
            
            completion: { (finished) -> Void in
                
                self.blockOperations.removeAll(keepCapacity: false)
        })
    }
    
    //MARK --- Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        let cellCount = self.fetchedResultsController.sections![section].numberOfObjects
        print("cell count in collection view: \(cellCount)")

        return cellCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoViewCell
        cell.activityIndicator.hidesWhenStopped = true
        
        if(thisPin.isGettingPhotos)
        {
            cell.imageView.image = UIImage(named: "photoDownloading")
            cell.activityIndicator.startAnimating()
        }
        else
        {
            let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            self.configureCell(cell, photo: photo)
            cell.activityIndicator.stopAnimating()
        }
        
        return cell
    }
    
    func configureCell(cell: PhotoViewCell, photo: Photo)
    {
        var image = UIImage(named: "photoNotFound")
        
        cell.imageView.image = nil
        
        //set the photo image
        if(photo.path == nil || photo.path == "")
        {
            image = UIImage(named: "photoNotFound")
        }
        else if(photo.photoImage != nil)
        {
            image = photo.photoImage
        }
        else // in this case the path is named but not yet downloaded
        {
            //print("path is named but not yet downloaded")
            if let imageURL = NSURL(string: photo.url_m)
            {
                if let imageData = NSData(contentsOfURL: imageURL)
                {
                    let foundImage = UIImage(data: imageData)
                    
                    photo.photoImage = foundImage
                    image = foundImage
                }
            }
            else
            {
                print("NSURL could not make a URL from photo.url_m")
            }
        }
        
        cell.imageView.image = image
    }
    
    //MARK --- Photo Client Stuff
    
    func findPhotos(pin: Location)
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
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
                pin.isGettingPhotos = false
            }
        }
    }
}