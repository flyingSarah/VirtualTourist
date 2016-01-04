//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Sarah Howe on 12/9/15.
//  Copyright © 2015 SarahHowe. All rights reserved.
//

import Foundation

class FlickrClient : NSObject {
    
    //shared session
    var session: NSURLSession
    
    //shared student location arrays
    var photos = [Photo]()
    
    override init()
    {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    //MARK --- Get
    func taskForGetMethod(parameters: [String : AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask
    {
        //build the url and configure the request
        let urlString = FlickrClient.Constants.BASE_URL + FlickrClient.escapedParameters(parameters)
        //print("attempting to request the following url:\n  \(urlString)")
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        //make the request
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            
            //parse and use the data (happens in completion handler)
            if let error = downloadError
            {
                let newError = FlickrClient.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            }
            else
            {
                FlickrClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        
        task.resume()
        return task
    }
    
    //MARK --- Helpers
    
    //given a response with error, see if a status_message is returned, otherwise return the previous error
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError?) -> NSError
    {
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject]
        {
            if let errorMessage = parsedResult[FlickrClient.JSONResponseKeys.STATUS] as? String
            {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                if let errorCode = parsedResult[FlickrClient.JSONResponseKeys.CODE] as? Int
                {
                    return NSError(domain: "Flickr Parse Error", code: errorCode, userInfo: userInfo)
                }
                
                return NSError(domain: "Flickr Parse Error", code: 0, userInfo: userInfo)
            }
        }
        
        return error!
    }
    
    //Given raw JSON, return a useable Foundation object
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void)
    {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError
        {
            completionHandler(result: nil, error: error)
        }
        else
        {
            if let _ = parsedResult?.valueForKey(FlickrClient.JSONResponseKeys.CODE) as? String
            {
                let newError = errorForData(data, response: nil, error: nil)
                completionHandler(result: nil, error: newError)
            }
            else
            {
                completionHandler(result: parsedResult, error: nil)
            }
            
        }
    }
    
    //given a dictionary of parameters, convert to a string for a url
    class func escapedParameters(parameters: [String : AnyObject]) -> String
    {
        let queryItems = parameters.map { NSURLQueryItem(name: $0, value: $1 as? String) }
        let components = NSURLComponents()
        
        components.queryItems = queryItems
        return components.percentEncodedQuery ?? ""
    }
    
    //MARK --- Shared Instance
    class func sharedInstance() -> FlickrClient
    {
        struct Singleton
        {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
    //MARK --- Shared Image Cache
    struct Caches
    {
        static let imageCache = ImageCache()
    }
}