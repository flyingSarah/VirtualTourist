//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Sarah Howe on 12/9/15.
//  Copyright © 2015 SarahHowe. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    //MARK --- Constants
    struct Constants
    {
        //api keys
        static let FLICKR_API_KEY : String = "220d9db60b6326d5a7b7e947a01cbe64"
        
        //URLs
        static let BASE_URL : String = "https://api.flickr.com/services/rest/?"
        
        static let MAX_TOTAL_PAGES = 40
        static let MAX_TOTAL_IMAGES = 21
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
    }
    
    //MARK --- Methods
    struct Methods
    {
        static let SEARCH : String = "flickr.photos.search"
    }
    
    //MARK --- Method Arguments and Keys
    struct MethodArgumentKeys
    {
        static let METHOD_NAME = "method"
        static let API_KEY = "api_key"
        static let BOUNDING_BOX = "bbox"
        static let SAFE_SEARCH = "safe_search"
        static let EXTRAS = "extras"
        static let FORMAT = "format"
        static let NO_JSON_CALLBACK = "nojsoncallback"
        static let MEDIA_TYPE = "media"
        static let LATITUDE = "lat"
        static let LONGITUDE = "long"
        static let PAGE = "page"
    }
    
    struct MethodArguments
    {
        static let SAFE_SEARCH = "1"
        static let EXTRAS = "url_m"
        static let FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let PHOTO_TYPE = "photos"
    }
    
    //MARK --- JSON Response Keys
    struct JSONResponseKeys
    {
        //errors
        static let STATUS = "stat"
        static let CODE = "code"
        static let MESSAGE = "message"
        
        //photos
        static let PHOTOS = "photos"
        static let PAGES = "pages"
        static let TOTAL = "total"
        static let TITLE = "title"
        static let PHOTO_URL = "url_m"
        static let BOUNDING_BOX = "bbox"
    }
}