//
//  FlickrAPI.swift
//  PhotoFrame
//
//  Manages interaction with Flickr API:
//      - constructs URLS for specific endpoints
//      - parses results received from the API
//
//  Created by Alexander on 7/19/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import UIKit
import CoreData

enum CollectionName: String {
    case interestingPhotos = "flickr.interestingness.getList"
    case recentPhotos = "flickr.photos.getRecent"
    case photosSearch = "flickr.photos.search"
}

enum FlickrError: Error {
    case invalidJSONData
}

struct FlickrAPI {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    /**
     Parses Flickr results into a photos array
     - Parameters:
        - data: Flickr response data
        - context: NSManagedObjectContext to use for Core Data operations
     
     - Returns: `PhotoResults` (declared in Networking.swift).
                An enum of either array of `Photo` objects or `Error`.
    */
    static func photos(fromJSON data: Data,
                       into context: NSManagedObjectContext) -> PhotosResult {
        
        // Attempts to deserialize Flickr response into JSON object
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            // Parsing Flickr response data structure
            guard
                let jsonDictionary  = jsonObject as? [AnyHashable:AnyObject],
                let photos          = jsonDictionary["photos"] as? [String:AnyObject],
                let photosArray     = photos["photo"] as? [[String:AnyObject]] else
            {
                // The JSON structure doesn't match expectations
                // Check Flickr API compliance
                return .failure(FlickrError.invalidJSONData)
            }
            
            // Parsing and saving pageNumber from Flickr response
            // pageNumber is used for successive image set requests
            let pageNumber = photos[Constants.FlickrResponseKeys.PageNumber] as! Int16
            PinDetailViewController.location.photoPageNumber = pageNumber
            
            // Parsing each photo from Flickr response into Photo objects
            // Saving them into final array to be returned by the function
            var finalPhotos = [Photo]()
            for photoJSON in photosArray {
                guard let photo = photo(fromJSON: photoJSON, into: context) else {
                    print("Cannot create photo object for: \n\(photoJSON)")
                    continue
                }
                finalPhotos.append(photo)
            }
            
            // If no images where parsed out of the Flickr photos response,
            // even so they were in present in it, return an error
            if finalPhotos.isEmpty && !photosArray.isEmpty {
                // Error parsing JSON
                return .failure(FlickrError.invalidJSONData)
            }
            
            // return array of Photo objects
            return .success(finalPhotos)
        } catch {
            return .failure(error)
        }
    }
    
    /**
     Converts photos from flickr results to Photo entity
     - Parameter json: Object representing a single photo from Flickr response data structure
     - Parameter context: NSManagedObjectContext to use for Core Data operations
    */
    private static func photo(fromJSON json: [String: AnyObject],
                              into context: NSManagedObjectContext) -> Photo? {
        
        // Required Values (must be present to be inserted into DB)
        guard
            let photoID         = json[Constants.FlickrResponseKeys.PhotoID] as? String,
            let owner           = json[Constants.FlickrResponseKeys.Owner] as? String
        else
        {
            return nil
        }
        
        // Parsing image urls from response object
        let urlSmallStr: String?
        let urlLargeStr: String?
        let urlOriginalStr: String?
        
        // Make URL large equal to itself or URL original, if large is not present,
        // if both are not present, fail
        if let url = json[Constants.FlickrResponseKeys.LargeURL] as? String {
            urlLargeStr = url
        } else if let url = json[Constants.FlickrResponseKeys.OriginalURL] as? String {
            urlLargeStr = url
        } else {
            return nil
        }
        
        // Make URL original equal to itself or URL large, if original is not present
        if let url  = json[Constants.FlickrResponseKeys.OriginalURL] as? String {
            urlOriginalStr = url
        } else {
            urlOriginalStr = urlLargeStr
        }
        
        // Assing urlLarge to urlSmall, if urlSmall is empty (since small is the one used for cell image)
        urlSmallStr = (json[Constants.FlickrResponseKeys.SmallURL] as? String) ?? urlLargeStr
        
        // Converting parsed out url strings into URL objects
        guard
            let urlSmall        = URL(string: urlSmallStr!),
            let urlLarge        = URL(string: urlLargeStr!),
            let urlOriginal     = URL(string: urlOriginalStr!)
        else {
            return nil
        }
        
        // Optional Values
        let title           = json[Constants.FlickrResponseKeys.Title] as? String
        let tags            = json[Constants.FlickrResponseKeys.Tags] as? String
        let latitude        = json[Constants.FlickrResponseKeys.Latitude] as? Double
        let longitude       = json[Constants.FlickrResponseKeys.Longitude] as? Double
        
        var dateTaken: Date?
        if let dateString   = json[Constants.FlickrResponseKeys.DateTaken] as? String {
            dateTaken       = dateFormatter.date(from: dateString)
        }
        
        // Creates new Photo object and saves parsed out values to its fields
        // NOTE the importance of context.performAndWait function, which makes
        // sure all the CoreData updates are done on a proper thread
        var photo: Photo!
        context.performAndWait {
            photo = Photo(context: context)
            
            // Required Fields
            photo.photoID       = photoID
            photo.owner         = owner
            photo.urlSmall      = urlSmall as NSURL
            photo.urlLarge      = urlLarge as NSURL
            photo.urlOriginal   = urlOriginal as NSURL
            photo.location      = PinDetailViewController.location
            
            // Optional Fields (only saved, if have data)
            if let title = title {
                photo.title     = title
            }
            if let tags = tags {
                photo.tags      = tags
            }
            if let latitude = latitude {
                photo.latitude  = latitude
            }
            if let longitude = longitude {
                photo.longitude = longitude
            }
            if let dateTaken = dateTaken {
                photo.dateTaken = dateTaken as NSDate
            }
            
        }
        
        return photo
    }
    
    /**
     Constructs Flickr URL
     - Parameter method: flickr API endpoint (method) to be called
     - Parameter parameters: additional query string parameters, required for the above endpoint
     */
    private static func flickrURL(method: CollectionName,
                                  parameters: [String:String]?) -> URL {
        var components = URLComponents(string: Constants.Flickr.BaseURLString)!
        
        var queryItems = [URLQueryItem]()
        
        // Adding base parameters for all requests
        let baseParams = [
            Constants.FlickrParameterKeys.Method: method.rawValue,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey
        ]
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        // Adding additional parameters, passed to the function
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = URLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        components.queryItems = queryItems
        
        return components.url!
    }
    
    /**
     External/Class method, used to construct URL for Photos Search Flickr API endpoint
     - Parameter params: additional API parameter, if needed
     - Returns: `URL` object for Flickr photosSearch API endpoint
     */
    static func photosSearchURL(params: [String:String]?) -> URL {
        
        var parameterList = [
            Constants.FlickrParameterKeys.Extras:
                "\(Constants.FlickrParameterValues.Tags)," +
                    "\(Constants.FlickrParameterValues.Views)," +
                    "\(Constants.FlickrParameterValues.DateTaken)," +
                    "\(Constants.FlickrParameterValues.SmallURL)," +
                    "\(Constants.FlickrParameterValues.LargeURL)," +
            "\(Constants.FlickrParameterValues.OriginalURL)",
            Constants.FlickrParameterKeys.NumberOfPhotosPerPage:
                Constants.FlickrParameterValues.NumberOfPhotosPerPage
        ]
        
        if let params = params {
            for (key, value) in params {
                parameterList[key] = value
            }
        }
        
        return flickrURL(method: .photosSearch,
                         parameters: parameterList)
    }
}
