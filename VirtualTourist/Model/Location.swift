//
//  Location.swift
//  VirtualTourist
//
//  Created by Sarah Howe on 12/3/15.
//  Copyright © 2015 SarahHowe. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class Location : NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: NSSet
    @NSManaged var alreadyGotPhotos: Bool
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude: Double, longitude: Double, context: NSManagedObjectContext)
    {
        
        // Get the entity associated with the "Location" type.
        let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        self.latitude = latitude
        self.longitude = longitude
        alreadyGotPhotos = false
    }
    
    //I set this up based dimitrios_108861's solution from this discussion thread: https://discussions.udacity.com/t/virtual-tourist-dragging-a-pin/28906/8
    var coordinate: CLLocationCoordinate2D {
        
        set(newValue)
        {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
        get {
            return CLLocationCoordinate2DMake(latitude as CLLocationDegrees, longitude as CLLocationDegrees)
        }
    }
}
