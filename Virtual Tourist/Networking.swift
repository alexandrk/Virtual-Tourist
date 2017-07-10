//
//  Networking.swift
//  Virtual Tourist
//
//  Created by Alexander on 7/06/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import Foundation
import UIKit

class Networking {
    
    // MARK: Properties
    
    // authentication state
    var userID: String! = nil
    var sessionID: String! = nil
    var requestToken: String! = nil

    // MARK: Network Functions GET/POST/etc.
    
    func taskForGetRequest(urlString : String,
                           completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        let request = NSMutableURLRequest(url: URL(string: urlString)!)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){ data, response, error in
            
            func sendError(_ error: String){
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode >= 200 && statusCode <= 299 else {
                    sendError("Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* Parse the data and use the data (happens in completion handler) */
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        task.resume()
        
    }
    
    // MARK: Helper Functions
    func requestImagesForLocation(latitude: Double,
                                  longitude: Double,
                                  withPageNumber: Int = 1,
                                  completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        func sendError(_ error: String){
            let userInfo = [NSLocalizedDescriptionKey : error]
            completionHandler(nil, NSError(domain: "requestImagesForLocation", code: 1, userInfo: userInfo))
        }
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude: latitude, longitude: longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.NumberOfPhotosPerPage: Constants.FlickrParameterValues.NumberOfPhotosPerPage,
            Constants.FlickrParameterKeys.Page: withPageNumber
        ] as [String : AnyObject]

        let urlString = flickrURLFromParameters(methodParameters)
        
        taskForGetRequest(urlString: String(describing: urlString), completionHandlerForGET: { (results, error) in
            
            guard let parsedResult = results else {
                sendError("ParsedResults are nil")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                sendError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                sendError("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                sendError("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            if photosArray.count == 0 {
                sendError("No Photos Found. Search Again.")
                return
            } else {
                completionHandler(photosArray as AnyObject, nil)
            }
        
        })
        
        
    }
    
    /**
     
    */
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    /**
     
     */
    private func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) -> Void{
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }

    // MARK: Shared Instance
    static let sharedInstance : Networking = Networking()
    
}
