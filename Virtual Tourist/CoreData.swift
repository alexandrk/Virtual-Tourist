//
//  CoreData.swift
//  Virtual Tourist
//
//  Created by Alexander on 7/11/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import MapKit
import CoreData


// TODO: Move all CoreData code here
class CoreData: NSObject {
    static let moc: NSManagedObjectContext = CoreData.persistentContainer.viewContext
    
    // MARK: - Core Data stack
    
    static var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: Constants.CoreDataValues.PinsPersistentContainer)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    static func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    static func createLocationObject() -> Location {
        return NSEntityDescription.insertNewObject(forEntityName: "Location", into: moc) as! Location
    }
    
    static func saveLocationToDB(coordinates: CLLocationCoordinate2D) -> Location {
        let location = CoreData.createLocationObject()
        location.latitude = coordinates.latitude
        location.longitude = coordinates.longitude
        location.created_at = NSDate()
        CoreData.saveContext()
        
        return location
    }
    
    /**
     Gets all existing Locations from the database
     - Returns: an optional array of `Location` objects
    */
    static func getExistingLocations() -> [Location]? {
        var locations: [Location]?
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        
        do {
            locations = try CoreData.moc.fetch(fetchRequest)
        } catch {
            print("Failed to perform fetch request: \(error.localizedDescription)")
        }
        
        return locations
    }
    
}
