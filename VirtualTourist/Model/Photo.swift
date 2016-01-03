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
        static let ImagePath = FlickrClient.JSONResponseKeys.PHOTO_URL
        static let Title = FlickrClient.JSONResponseKeys.TITLE
    }
    
    @NSManaged var url_m: String
    @NSManaged var title: String
    @NSManaged var location: Location?
    
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
        url_m = dictionary[Keys.ImagePath] as! String
        title = dictionary[Keys.Title] as! String
    }
    
    //given an array of dictionaries, convert them to an array of Student Location result objects
    static func photosFromResults(results: [[String : AnyObject]]) -> [Photo]
    {
        var photos = [Photo]()
        
        for result in results
        {
            //for now I'm just saving the image title and url
            let filteredResult: [String: AnyObject] = [Keys.Title: result[Keys.Title]!, Keys.ImagePath: result[Keys.ImagePath]!]
            //print("photosFromResults -----------------\n\(filteredResult)\n")
            photos.append(Photo(dictionary: filteredResult, context: CoreDataStackManager.sharedInstance().managedObjectContext))
        }
        
        return photos
    }
    
    /*var image: UIImage? {
        
        get {
            return TheMovieDB.Caches.imageCache.imageWithIdentifier(posterPath)
        }
        
        set {
            TheMovieDB.Caches.imageCache.storeImage(newValue, withIdentifier: posterPath!)
        }
    }*/
}
