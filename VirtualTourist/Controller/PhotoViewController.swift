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
    @IBOutlet weak var masterActivityIndicator: UIActivityIndicatorView!
    
    //MARK --- Useful Variables
    
    var thisPin: Pin!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected".
    var selectedIndexes = [IndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    
    //MARK --- Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapView.isUserInteractionEnabled = false
        
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
            showAlertController("Error Fetching Photos", message: String(describing: error))
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        noPhotosFound.isHidden = true
        
        if(!thisPin.location!.alreadyGotPhotos)
        {
            //print("this pin doesn't already have its photos")
            
            masterActivityIndicator.startAnimating()
            bottomButton.isEnabled = false
            findPhotos(thisPin.location!)
        }
    }
    
    //MARK --- Refresh and/or Delete Behavior
    
    @IBAction func bottomButtonTriggered(_ sender: UIBarButtonItem)
    {
        if(sender.title == "New Collection")
        {
            getNewCollection()
        }
        else
        {
            deleteSelectedPhotos()
        }
    }
    
    func getNewCollection()
    {
        masterActivityIndicator.startAnimating()
        
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects
        {
            //delete existing photos
            for object in fetchedObjects
            {
                let photo = object 
                self.sharedContext.delete(photo)
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        //find new photos
        findPhotos(thisPin.location!)
    }
    
    func deleteSelectedPhotos()
    {
        var photosToDelete = [Photo]()
        
        for selectedIndex in selectedIndexes
        {
            photosToDelete.append(fetchedResultsController.object(at: selectedIndex) )
        }
        
        for photo in photosToDelete
        {
            sharedContext.delete(photo)
        }
        
        selectedIndexes = [IndexPath]()
        bottomButton.title = "New Collection"
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    //MARK --- Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = {
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "uniqueId", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.thisPin.location!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController as! NSFetchedResultsController<Photo>
        
        }()
    
    //MARK --- Fetched Results Controller Delegate Methods
    
    //I learned how to adapt the collection view for these methods from this stack overflow topic: http://stackoverflow.com/questions/20554137/nsfetchedresultscontollerdelegate-for-collectionview
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
        case .move:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        collectionView.performBatchUpdates({ () -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
        }, completion: nil)
    }
    
    //MARK --- Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        let cellCount = self.fetchedResultsController.sections![section].numberOfObjects
        return cellCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
        
        cell.layer.borderColor = UIColor(red: 0.92, green: 0.0, blue: 0.55, alpha: 0.6).cgColor
        cell.layer.borderWidth = 0.0
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(_ cell: PhotoViewCell, atIndexPath indexPath: IndexPath)
    {
        let photo = fetchedResultsController.object(at: indexPath) 
        
        if let image = photo.photoImage
        {
            photo.loadUpdateHandler = nil
            self.noPhotosFound.isHidden = true
            cell.imageView.image = image
            cell.activityIndicator.stopAnimating()
        }
        else
        {
            noPhotosFound.isHidden = true
            
            photo.loadUpdateHandler = nil
            cell.imageView.image = UIImage(named: "photoDownloading")
            cell.activityIndicator.startAnimating()
            
            if let imageURL = URL(string: photo.url_m)
            {
                FlickrClient.sharedInstance.downloadImage(imageURL) { data, error in
                    
                    if let error = error
                    {
                        print("error downloading photos from imageURL: \(imageURL) \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            photo.loadUpdateHandler = nil
                            cell.imageView.image = UIImage(named: "photoNotFound")
                            cell.activityIndicator.stopAnimating()
                        }
                    }
                    else
                    {
                        DispatchQueue.main.async {
                            
                            if let photoImage = UIImage(data: data!)
                            {
                                photo.loadUpdateHandler = { [unowned self] () -> Void in
                                    DispatchQueue.main.async(execute: {
                                        self.collectionView.reloadItems(at: [indexPath])
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        //allows you to deselect items even if it was the last item you selected
        collectionView.deselectItem(at: indexPath, animated: false)
        
        let cell = collectionView.cellForItem(at: indexPath)!
        
        if let _ = selectedIndexes.index(of: indexPath)
        {
            cell.layer.borderWidth = 0.0
            
            let selectedIndex = selectedIndexes.index(of: indexPath)
            selectedIndexes.remove(at: selectedIndex!)
        }
        else
        {
            cell.layer.borderWidth = 4.0
            
            selectedIndexes.append(indexPath)
        }
        
        //allow deleting if any photos are selected
        if(selectedIndexes.count > 0)
        {
            bottomButton.title = "Delete Selected Photos"
        }
        else
        {
            bottomButton.title = "New Collection"
        }
    }
    
    //MARK --- Photo Client Stuff
    
    func findPhotos(_ pin: Location)
    {
        pin.alreadyGotPhotos = true
        
        //find the photos for the selected latitude and longitude
        FlickrClient.sharedInstance.getPhotos(pin) { result, error in
            
            if let error = error
            {
                //print("error getting photos from lat/lon:\n  \(error.code)\n  \(error.localizedDescription)")
                
                self.showAlertController("Error Getting Photos", message: error.localizedDescription)
                
                DispatchQueue.main.async {
                    self.noPhotosFound.isHidden = false
                }
            }
            else
            {
                DispatchQueue.main.async {
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
            
            DispatchQueue.main.async {
                self.masterActivityIndicator.stopAnimating()
                self.bottomButton.isEnabled = true
            }
        }
    }
    
    //MARK --- Helper functions
    
    func showAlertController(_ title: String, message: String)
    {
        DispatchQueue.main.async(execute: {
            
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
        })
    }
}
