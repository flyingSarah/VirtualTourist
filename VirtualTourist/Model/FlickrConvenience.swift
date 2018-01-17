//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Sarah Howe on 12/13/15.
//  Copyright © 2015 SarahHowe. All rights reserved.
//

import UIKit
import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


extension FlickrClient {
    
    //MARK: Student Location Methods
    
    func getPhotos(_ pin: Location, completionHandler: @escaping (_ result: NSSet?, _ error: NSError?) -> Void)
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
            taskForGetMethod(parameters as [String : AnyObject]) { JSONResult, error in
                
                //send the desired values to the completion handler
                if let error = error
                {
                    completionHandler(nil, error)
                }
                else
                {
                    if let results = JSONResult?.value(forKey: FlickrClient.JSONResponseKeys.PHOTOS) as? NSDictionary
                    {
                        if let totalPages = results.value(forKey: FlickrClient.JSONResponseKeys.PAGES) as? Int
                        {
                            //flickr will only return up to 4000 images (100 per page & 40 page max)
                            let pageLimit = min(totalPages, FlickrClient.Constants.MAX_TOTAL_PAGES)
                            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                            let pageNumberString = String(randomPage)
                            var pageAddedParameters = parameters
                            pageAddedParameters[FlickrClient.MethodArgumentKeys.PAGE] = pageNumberString
                            
                            self.taskForGetMethod(pageAddedParameters as [String : AnyObject]) { pageAddedJSONResult, pageAddedError in
                                
                                if let pageAddedError = pageAddedError
                                {
                                    completionHandler(nil, pageAddedError)
                                }
                                else
                                {
                                    if let photosDictionary = pageAddedJSONResult?.value(forKey: FlickrClient.JSONResponseKeys.PHOTOS) as? NSDictionary
                                    {
                                        if let totalPhotosString = photosDictionary.value(forKey: FlickrClient.JSONResponseKeys.TOTAL) as? String
                                        {
                                            let totalPhotos = Int(totalPhotosString)
                                            
                                            if(totalPhotos > 0)
                                            {
                                                if let photoArray = photosDictionary.value(forKey: "photo") as? [[String : AnyObject]]
                                                {
                                                    if(photoArray.count > 0)
                                                    {
                                                        print("Successfully found \(photoArray.count) photos from Flickr")
                                                        
                                                        let photos = Photo.photosFromResults(photoArray, location: pin)
                                                        FlickrClient.sharedInstance.photos = photos
                                                        
                                                        completionHandler(photos, nil)
                                                    }
                                                    else
                                                    {
                                                        //I noticed that sometimes Flickr returns an empty photo array when I use the page parameter to search.  After much testing I decided it must be a Flickr bug so I decided to just get Page 1's results in those cases so that I will always be able to display photos if there are any to display.
                                                        
                                                        if let totalPageOnePhotosString = results.value(forKey: FlickrClient.JSONResponseKeys.TOTAL) as? String
                                                        {
                                                            let totalPageOnePhotos = Int(totalPageOnePhotosString)
                                                            
                                                            if(totalPageOnePhotos > 0)
                                                            {
                                                                if let pageOnePhotoArray = results.value(forKey: "photo") as? [[String : AnyObject]]
                                                                {
                                                                    if(pageOnePhotoArray.count > 1)
                                                                    {
                                                                        print("Successfully found \(pageOnePhotoArray.count) photos from Page 1 of Flickr results")
                                                                        
                                                                        let photos = Photo.photosFromResults(pageOnePhotoArray, location: pin)
                                                                        FlickrClient.sharedInstance.photos = photos
                                                                        
                                                                        completionHandler(photos, nil)
                                                                    }
                                                                    else
                                                                    {
                                                                        completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Photos array was empty on Page 1 of Flickr Results"]))
                                                                    }
                                                                    
                                                                }
                                                                else
                                                                {
                                                                    completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not find photo key from Page 1 of Flickr result"]))
                                                                }
                                                            }
                                                            else
                                                            {
                                                                completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Found 0 photos from Page 1 of Flickr result"]))
                                                            }
                                                        }
                                                        else
                                                        {
                                                            completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not find total photos key from Page 1 of Flickr result"]))
                                                        }
                                                    }
                                                }
                                                else
                                                {
                                                    completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not find photo key from Flickr result"]))
                                                }
                                            }
                                            else
                                            {
                                                completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Found 0 photos from Flickr result"]))
                                            }
                                        }
                                        else
                                        {
                                            completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not find total photos key from Flickr result"]))
                                        }
                                    }
                                }
                            }
                        }
                        else
                        {
                            completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not find total pages key from Flickr result"]))
                        }
                    }
                    else
                    {
                        completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not aquire photos from Flickr result"]))
                    }
                }
            }
        }
        else
        {
            if (!validLat && !validLon)
            {
                completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Lat/Lon Invalid.\nLat should be [-90, 90].\nLon should be [-180, 180]."]))
            }
            else if (!validLat)
            {
                completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Lat Invalid.\nLat should be [-90, 90]."]))
            }
            else
            {
                completionHandler(nil, NSError(domain: "getPhotos parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Lon Invalid.\nLon should be [-180, 180]."]))
            }
        }
    }
    
    /* Check to make sure the latitude falls within [-90, 90] */
    func validLatitude(_ latitude: Double) -> Bool
    {
        if (latitude < FlickrClient.Constants.LAT_MIN || latitude > FlickrClient.Constants.LAT_MAX)
        {
            return false
        }
        
        return true
    }
    
    func validLongitude(_ longitude: Double) -> Bool
    {
        if (longitude < FlickrClient.Constants.LON_MIN || longitude > FlickrClient.Constants.LON_MAX)
        {
            return false
        }
        
        return true
    }
    
    func createBoundingBoxString(_ latitude: Double, longitude: Double) -> String!
    {
        //ensure box is bounded by minimum and maximum allowed values
        let bottom_left_lon = max(longitude - FlickrClient.Constants.BOUNDING_BOX_HALF_WIDTH, FlickrClient.Constants.LON_MIN)
        let bottom_left_lat = max(latitude - FlickrClient.Constants.BOUNDING_BOX_HALF_HEIGHT, FlickrClient.Constants.LAT_MIN)
        let top_right_lon = min(longitude + FlickrClient.Constants.BOUNDING_BOX_HALF_WIDTH, FlickrClient.Constants.LON_MAX)
        let top_right_lat = min(latitude + FlickrClient.Constants.BOUNDING_BOX_HALF_HEIGHT, FlickrClient.Constants.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
}
