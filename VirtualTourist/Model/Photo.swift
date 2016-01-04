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
    }
    
    @NSManaged var url_m: String
    @NSManaged var path: String?
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
        url_m = dictionary[Keys.ImageURL] as! String
        path = dictionary[Keys.ImagePath] as? String
        title = dictionary[Keys.Title] as! String
        location = dictionary[Keys.Location] as? Location
    }
    
    //given an array of dictionaries, convert them to an array of Student Location result objects
    static func photosFromResults(results: [[String : AnyObject]], location: Location) -> [Photo]
    {
        var photos = [Photo]()
        
        for result in results
        {
            //format the image path
            let imageURL = NSURL(string: result[Keys.ImageURL] as! String)!
            let imagePath = "/\(imageURL.lastPathComponent!)" ?? ""
            
            //for now I'm just saving the image title and url
            let filteredResult: [String: AnyObject] = [Keys.Title: result[Keys.Title]!, Keys.ImageURL: result[Keys.ImageURL]!, Keys.ImagePath: imagePath, Keys.Location: location]
            //print("photosFromResults -----------------\n\(filteredResult)\n")
            photos.append(Photo(dictionary: filteredResult, context: CoreDataStackManager.sharedInstance().managedObjectContext))
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
        }
    }
}
