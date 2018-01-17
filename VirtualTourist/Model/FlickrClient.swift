//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Sarah Howe on 12/9/15.
//  Copyright © 2015 SarahHowe. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient : NSObject {
    
    static let sharedInstance = FlickrClient()
    
    //shared session
    var session: URLSession
    
    //shared student location arrays
    var photos = NSSet()
    
    override init()
    {
        session = URLSession.shared
        super.init()
    }
    
    //MARK --- Get
    func taskForGetMethod(_ parameters: [String : AnyObject], completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask
    {
        //build the url and configure the request
        let urlString = FlickrClient.Constants.BASE_URL + FlickrClient.escapedParameters(parameters)
        //print("attempting to request the following url:\n  \(urlString)")
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        
        //make the request
        let task = session.dataTask(with: request, completionHandler: { data, response, downloadError in
            
            //parse and use the data (happens in completion handler)
            if let error = downloadError
            {
                let newError = FlickrClient.errorForData(data, response: response, error: error as NSError)
                completionHandler(nil, newError)
            }
            else
            {
                FlickrClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }) 
        
        task.resume()
        return task
    }
    
    //MARK --- Download
    func downloadImage(_ url: URL, completionHandler: @escaping (_ data: Data?, _ error: NSError?) -> Void) -> Void
    {
        let request = URLRequest(url: url)
        
        //make the request
        let task = session.dataTask(with: request, completionHandler: { data, response, downloadError in
            
            //parse and use the data (happens in completion handler)
            if let error = downloadError
            {
                let newError = FlickrClient.errorForData(data, response: response, error: error as NSError)
                completionHandler(nil, newError)
            }
            else
            {
                completionHandler(data, nil)
            }
        }) 
        
        task.resume()
    }
    
    //MARK --- Helpers
    
    //given a response with error, see if a status_message is returned, otherwise return the previous error
    class func errorForData(_ data: Data?, response: URLResponse?, error: NSError?) -> NSError
    {
        if let parsedResult = (try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)) as? [String : AnyObject]
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
    class func parseJSONWithCompletionHandler(_ data: Data, completionHandler: (_ result: AnyObject?, _ error: NSError?) -> Void)
    {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        
        do
        {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as AnyObject
        }
        catch let error as NSError
        {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError
        {
            completionHandler(nil, error)
        }
        else
        {
            if let _ = parsedResult?.value(forKey: FlickrClient.JSONResponseKeys.CODE) as? String
            {
                let newError = errorForData(data, response: nil, error: nil)
                completionHandler(nil, newError)
            }
            else
            {
                completionHandler(parsedResult, nil)
            }
            
        }
    }
    
    //given a dictionary of parameters, convert to a string for a url
    class func escapedParameters(_ parameters: [String : AnyObject]) -> String
    {
        let queryItems = parameters.map { URLQueryItem(name: $0, value: $1 as? String) }
        var components = URLComponents()
        
        components.queryItems = queryItems
        return components.percentEncodedQuery ?? ""
    }
    
    //MARK --- Shared Image Cache
    struct Caches
    {
        static let imageCache = ImageCache()
    }
}
