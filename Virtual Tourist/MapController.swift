//
//  MapController.swift
//  Virtual Tourist
//
//  Created by Alexander on 7/18/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import MapKit

class MapController: NSObject {
    
    static var mapViewReference: MKMapView!
    private static var regionRadius: CLLocationDistance = 2000 // 1km
    
    /**
     Manages creation of annotation and its addition to the map, through `mapViewReference`
     - Parameter location: Core Data Locations item
     */
    static func createAnnotation(from location: Location) -> MKPointAnnotation {
        let annotation = MyMKPointAnnotation()
        annotation.title = location.label
        annotation.coordinate.latitude = location.latitude
        annotation.coordinate.longitude = location.longitude
        annotation.location = location
        mapViewReference.addAnnotation(annotation)
        
        return annotation
    }
    
    /**
     Used to center the map on a given location.
     - Parameter coordinate: `CLLocationCoordinate2D` to center the map on
     */
    static func centerMapOnLocation(coordinate: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapViewReference.setRegion(coordinateRegion, animated: true)
    }

    
}
