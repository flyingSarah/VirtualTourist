//
//  Photo.swift
//  VirtualTourist
//
//  Created by Sarah Howe on 12/3/15.
//  Copyright © 2015 SarahHowe. All rights reserved.
//

import UIKit
import CoreData

class Photo : NSManagedObject {
    
    struct Keys
    {
        static let ImageURL = FlickrClient.JSONResponseKeys.PHOTO_URL
        static let ImagePath = "path"
        static let Title = FlickrClient.JSONResponseKeys.TITLE
        static let Location = "location"
        static let UniqueID = "uniqueId"
    }
    
    @NSManaged var url_m: String
    @NSManaged var path: String?
    @NSManaged var title: String
    @NSManaged var location: Location?
    @NSManaged var uniqueId: NSNumber
    
    //var loadUpdateHandler: (() -> Void)?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Person" type.  This is an object that contains
        // the information from the Model.xcdatamodeld file. We will talk about this file in
        // Lesson 4.
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Person class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary. This works in the same way that it did before we started on Core Data
        url_m = dictionary[Keys.ImageURL] as! String
        path = dictionary[Keys.ImagePath] as? String
        title = dictionary[Keys.Title] as! String
        location = dictionary[Keys.Location] as? Location
        uniqueId = dictionary[Keys.UniqueID] as! NSNumber
    }
    
    //given an array of dictionaries, convert them to an array of Student Location result objects
    static func photosFromResults(results: [[String : AnyObject]], location: Location) -> NSSet
    {
        var photos = NSSet()
        
        //find out how many picture I can download from the results
        var maxResults = FlickrClient.Constants.MAX_TOTAL_IMAGES
        let originalResultCount = results.count
        var countResults = 0
        //I don't want to just be limited to only the first group of the page
        var startCount = 0
        
        if(originalResultCount < maxResults)
        {
            maxResults = originalResultCount
        }
        else
        {
            startCount = Int(arc4random_uniform(UInt32(originalResultCount - maxResults)))
        }
        
        for result in results
        {
            if(countResults < (maxResults + startCount) && countResults >= startCount)
            {
                //format the image path
                if let imageURL = NSURL(string: result[Keys.ImageURL] as! String)
                {
                    let imagePath = "/\(imageURL.lastPathComponent!)" ?? ""
                    
                    //for now I'm just saving the image title and url
                    let filteredResult: [String: AnyObject] = [Keys.Title: result[Keys.Title]!, Keys.ImageURL: result[Keys.ImageURL]!, Keys.ImagePath: imagePath, Keys.Location: location, Keys.UniqueID: countResults]
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        print("photo \(photos.count) will download")
                        photos = photos.setByAddingObject(Photo(dictionary: filteredResult, context: CoreDataStackManager.sharedInstance().managedObjectContext))
                    }
                    
                }
                else
                {
                    print("FROM PHOTO RESULTS: photo url could not be converted to NSURL")
                }
            }
            
            countResults++
        }
        
        return photos
    }
    
    var photoImage: UIImage? {
        
        get
        {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(path)
        }
        
        set
        {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: path!)
            
            dispatch_async(dispatch_get_main_queue()) {
                CoreDataStackManager.sharedInstance().saveContext()
            }
            //loadUpdateHandler?()
        }
    }
}
