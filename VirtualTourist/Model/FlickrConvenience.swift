//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Sarah Howe on 12/13/15.
//  Copyright © 2015 SarahHowe. All rights reserved.
//

import UIKit
import Foundation

extension FlickrClient {
    
    //MARK: Student Location Methods
    
    func getPhotos(pin: Location, completionHandler: (result: NSSet?, error: NSError?) -> Void)
    {
        //specify parameters and method
        let validLat = validLatitude(pin.latitude)
        let validLon = validLongitude(pin.longitude)
        
        if (validLat && validLon)
        {
            //set method arguments
            let parameters = [
                FlickrClient.MethodArgumentKeys.METHOD_NAME: FlickrClient.Methods.SEARCH,
                FlickrClient.MethodArgumentKeys.API_KEY: FlickrClient.Constants.FLICKR_API_KEY,
                FlickrClient.MethodArgumentKeys.BOUNDING_BOX:   createBoundingBoxString(pin.latitude, longitude: pin.longitude),
                FlickrClient.MethodArgumentKeys.EXTRAS: FlickrClient.MethodArguments.EXTRAS,
                FlickrClient.MethodArgumentKeys.FORMAT: FlickrClient.MethodArguments.FORMAT,
                FlickrClient.MethodArgumentKeys.NO_JSON_CALLBACK: FlickrClient.MethodArgumentKeys.NO_JSON_CALLBACK,
                FlickrClient.MethodArgumentKeys.MEDIA_TYPE: FlickrClient.MethodArguments.PHOTO_TYPE
            ]
            
            //make the request
            taskForGetMethod(parameters) { JSONResult, error in
                
                //send the desired values to the completion handler
                if let error = error
                {
                    completionHandler(result: nil, error: error)
                }
                else
                {
                    if let results = JSONResult.valueForKey(FlickrClient.JSONResponseKeys.PHOTOS) as? NSDictionary
                    {
                        if let totalPages = results.valueForKey(FlickrClient.JSONResponseKeys.PAGES) as? Int
                        {
                            //flickr will only return up to 4000 images (100 per page & 40 page max)
                            let pageLimit = min(totalPages, FlickrClient.Constants.MAX_TOTAL_PAGES)
                            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                            let pageNumberString = String(randomPage)
                            var pageAddedParameters = parameters
                            pageAddedParameters[FlickrClient.MethodArgumentKeys.PAGE] = pageNumberString
                            
                            self.taskForGetMethod(pageAddedParameters) { pageAddedJSONResult, pageAddedError in
                                
                                if let pageAddedError = pageAddedError
                                {
                                    completionHandler(result: nil, error: pageAddedError)
                                }
                                else
                                {
                                    if let photos = pageAddedJSONResult.valueForKey(FlickrClient.JSONResponseKeys.PHOTOS) as? NSDictionary
                                    {
                                        if let totalPhotosString = photos.valueForKey(FlickrClient.JSONResponseKeys.TOTAL) as? String
                                        {
                                            let totalPhotos = Int(totalPhotosString)
                                            
                                            if(totalPhotos > 0)
                                            {
                                                if let photoArray = photos.valueForKey("photo") as? [[String : AnyObject]]
                                                {
                                                    print("Successfully found photos from Flickr")
                                                    let photos = Photo.photosFromResults(photoArray, location: pin)
                                                    FlickrClient.sharedInstance().photos = photos
                                                    
                                                    completionHandler(result: photos, error: nil)
                                                }
                                                else
                                                {
                                                    completionHandler(result: nil, error: NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not find photo key from Flickr result"]))
                                                }
                                            }
                                        }
                                        else
                                        {
                                            completionHandler(result: nil, error: NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not find total photos key from Flickr result"]))
                                        }
                                    }
                                }
                            }
                        }
                        else
                        {
                            completionHandler(result: nil, error: NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not find total pages key from Flickr result"]))
                        }
                    }
                    else
                    {
                        completionHandler(result: nil, error: NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not aquire photos from Flickr result"]))
                    }
                }
            }
        }
        else
        {
            if (!validLat && !validLon)
            {
                completionHandler(result: nil, error: NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Lat/Lon Invalid.\nLat should be [-90, 90].\nLon should be [-180, 180]."]))
            }
            else if (!validLat)
            {
                completionHandler(result: nil, error: NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Lat Invalid.\nLat should be [-90, 90]."]))
            }
            else
            {
                completionHandler(result: nil, error: NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Lon Invalid.\nLon should be [-180, 180]."]))
            }
        }
    }
    
    /* Check to make sure the latitude falls within [-90, 90] */
    func validLatitude(latitude: Double) -> Bool
    {
        if (latitude < FlickrClient.Constants.LAT_MIN || latitude > FlickrClient.Constants.LAT_MAX)
        {
            return false
        }
        
        return true
    }
    
    func validLongitude(longitude: Double) -> Bool
    {
        if (longitude < FlickrClient.Constants.LON_MIN || longitude > FlickrClient.Constants.LON_MAX)
        {
            return false
        }
        
        return true
    }
    
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String!
    {
        //ensure box is bounded by minimum and maximum allowed values
        let bottom_left_lon = max(longitude - FlickrClient.Constants.BOUNDING_BOX_HALF_WIDTH, FlickrClient.Constants.LON_MIN)
        let bottom_left_lat = max(latitude - FlickrClient.Constants.BOUNDING_BOX_HALF_HEIGHT, FlickrClient.Constants.LAT_MIN)
        let top_right_lon = min(longitude + FlickrClient.Constants.BOUNDING_BOX_HALF_WIDTH, FlickrClient.Constants.LON_MAX)
        let top_right_lat = min(latitude + FlickrClient.Constants.BOUNDING_BOX_HALF_HEIGHT, FlickrClient.Constants.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
}