//
//  ImageStore.swift
//  PhotoFrame
//
//  Created by Alexander on 7/25/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import UIKit

class ImageStore: NSObject {

    let cache = NSCache<NSString, UIImage>()
    
    /**
     Saves image to cache and disk
     - Parameter image: bit data of the image to be saved
     - Parameter forKey: **key** to lookup the image in cache and **filename** the image will have on disk
    */
    func setImage(_ image: UIImage, forKey key: String) {
        
        // Save image in cache
        cache.setObject(image, forKey: key as NSString)
        
        // Create full URL for image
        let url = imageURL(forKey: key)
        
        // Turn image into PNG data
        if let data = UIImagePNGRepresentation(image) {
            // Write image to filesystem
            let _ = try? data.write(to: url, options: [.atomic])
        }
    }
    
    func image(forKey key: String) -> UIImage? {
        
        // Check cache for the image
        if let existingImage = cache.object(forKey: key as NSString) {
            return existingImage
        }
        
        // If no image in cache, check the filesystem
        let url = imageURL(forKey: key)
        guard let imageFromDisk = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        
        // Save image from filesystem to cach and return the image
        cache.setObject(imageFromDisk, forKey: key as NSString)
        
        return imageFromDisk
    }
    
    func deleteImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        
        // Remove image from the filesystem
        let url = imageURL(forKey: key)
        
        do {
            // Checks if file exists, before attempting to delete it
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
        catch {
            print("Erorr removing the image from disk: \(error.localizedDescription)")
        }
        
    }
    
    func imageURL(forKey key: String) -> URL {
        let documentsDirectories =
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        
        return documentDirectory.appendingPathComponent(key)
    }
    
}
