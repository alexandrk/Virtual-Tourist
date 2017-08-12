//
//  Networking.swift
//  Virtual Tourist
//
//  Responsible for all Network operations
//
//  Created by Alexander on 7/06/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import Foundation
import UIKit

/**
 Used to store results of image request
*/
enum ImageResult {
    case success(UIImage)
    case failure(Error)
}

enum PhotoError: Error {
    case imageCreationError
}

/**
 Used to store results of DB query for Photo data
*/
enum PhotosResult {
    case success([Photo])
    case failure(Error)
}

class Networking {
    
    // MARK: Properties
    static let imageStore = ImageStore()
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    // MARK: Fetch Flickr Photos
    
    /**
     Fetches data from Flickr web service for a given location
     */
    func fetchFlickrPhotosForLocation(
        lat latitude: Double,
        long longitude: Double,
        extraRequrstParameters: [String: String] = [String:String](),
        completion: @escaping (PhotosResult) -> Void) {
        
        // Construcring Flickr Bounding Box parameter for the request
        let flickrBoundingBox = bboxString(latitude: latitude, longitude: longitude)
        
        var params = extraRequrstParameters
        params[Constants.FlickrParameterKeys.BoundingBox] = flickrBoundingBox
        
        let url = FlickrAPI.photosSearchURL(params: params)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            let result = self.processPhotosRequest(data: data, error: error)
            
            // Process the completion handler on the main queue
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    /**
     Helps to process the response from Flickr API
     */
    private func processPhotosRequest(data: Data?, error: Error?) -> PhotosResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return FlickrAPI.photos(fromJSON: jsonData, into: CoreData.persistentContainer.viewContext)
    }
    
    func fetchImage(for photo: Photo, completion: @escaping (ImageResult) -> Void) {
        
        // Check cache for the image before attempting to download it
        guard let photoKey = photo.photoID else {
            preconditionFailure("Photo expected to have a photoID.")
        }
        if let image = Networking.imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        
        guard let photoURL = photo.urlSmall else {
            preconditionFailure("Photo expected to have a remote URL.")
        }
        let request = URLRequest(url: photoURL as URL)
        
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            let result = self.processImageRequest(data: data, error: error)
            
            // Save image to cache
            if case let .success(image) = result {
                Networking.imageStore.setImage(image, forKey: photoKey)
            }
            
            // Process the completion handler on the main queue
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
        
    }
    
    private func processImageRequest(data: Data?, error: Error?) -> ImageResult {
        guard
            let imageData = data,
            let image = UIImage(data: imageData) else {
                
                // Couldn't create an image
                if data == nil {
                    return .failure(error!)
                }
                else {
                    return .failure(PhotoError.imageCreationError)
                }
        }
        return .success(image)
    }
    
    /**
     Helper function that creates Flickr bounding box paramter values from poin coordinates
    */
    private func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }

    // MARK: Shared Instance
    static let sharedInstance : Networking = Networking()
    
}
