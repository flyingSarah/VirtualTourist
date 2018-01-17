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
    
    var loadUpdateHandler: (() -> Void)?
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertInto: context)
    }
    
    override func prepareForDeletion()
    {
        super.prepareForDeletion()
        
        if let path = path
        {
            if(FileManager.default.fileExists(atPath: path))
            {
                do
                {
                    try FileManager.default.removeItem(atPath: path)
                }
                catch
                {
                    NSLog("could not delete photo at \(path): \(error)")
                }
            }
        }
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext)
    {
        
        // Get the entity associated with the "Photo" type.
        let entity =  NSEntityDescription.entity(forEntityName: "Photo", in: context)!
        
        super.init(entity: entity, insertInto: context)
        
        url_m = dictionary[Keys.ImageURL] as! String
        path = dictionary[Keys.ImagePath] as? String
        title = dictionary[Keys.Title] as! String
        location = dictionary[Keys.Location] as? Location
        uniqueId = dictionary[Keys.UniqueID] as! NSNumber
    }
    
    //given an array of dictionaries, convert them to an array of photo result objects
    static func photosFromResults(_ results: [[String : AnyObject]], location: Location) -> NSSet
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
                if let imageURL = URL(string: result[Keys.ImageURL] as! String)
                {
                    let imagePath = "/\(imageURL.lastPathComponent)" 
                    
                    //for now I'm just saving the image title and url
                    let filteredResult: [String: AnyObject] = [Keys.Title: result[Keys.Title]!, Keys.ImageURL: result[Keys.ImageURL]!, Keys.ImagePath: imagePath as AnyObject, Keys.Location: location, Keys.UniqueID: countResults as AnyObject]
                    
                    DispatchQueue.main.async {
                        
                        //print("photo \(photos.count) will download")
                        photos = photos.adding(Photo(dictionary: filteredResult, context: CoreDataStackManager.sharedInstance().managedObjectContext)) as NSSet
                    }
                    
                }
                else
                {
                    print("FROM PHOTO RESULTS: photo url could not be converted to NSURL")
                }
            }
            
            countResults += 1
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
            
            loadUpdateHandler?()
        }
    }
}
