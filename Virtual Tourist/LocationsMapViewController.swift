//
//  LocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Alexander on 7/6/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import UIKit
import MapKit

class LocationsMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    fileprivate var longPressGesture: UILongPressGestureRecognizer!
    fileprivate var locations: [Location]?
    @IBOutlet weak var editPinsButton: UIBarButtonItem!
    @IBOutlet weak var pinDeleteInfoLabel: UILabel!
    @IBOutlet weak var mapViewBottomConstraint: NSLayoutConstraint!
    
    // Required for resetting mapViewReference after DetailViewController Pop
    override func viewWillAppear(_ animated: Bool) {
        MapController.mapViewReference = mapView
        navigationItem.title = Constants.AppStrings.AppName
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set map view delegate with controller
        mapView.delegate = self
        
        // REMOVE
        let documentsDirectories =
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(documentsDirectories.first!)
        
        // Setting mapView reference in the MapController class
        MapController.mapViewReference = mapView
        
        // Add Existing Locations from the database
        plotExistingLocations()
        
        // Gesture Recognizer (Enable)
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPin))
        longPressGesture.minimumPressDuration = 0.5
        gestureRecognizer(enable: true)
        
    }

    /**
     Checks if there are any locations in the database and adds them to the map
    */
    func plotExistingLocations() {
        locations = CoreData.getExistingLocations()
        
        if let locations = locations {
            for location in locations {
                
                // Creates annotation and add it to map
                _ = MapController.createAnnotation(from: location)
                
            }
        }
    }
    
    /**
     MKMapViewDelegate function, called on annotation load to create Annotation Views
     Used here to disable callout for annotations
    */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView: MKAnnotationView! = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.DetailVCValues.AnnotationViewIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: Constants.DetailVCValues.AnnotationViewIdentifier)
        }
        
        // Disables the callout
        annotationView.canShowCallout = false
        
        annotationView.image = #imageLiteral(resourceName: "MapPin")
        annotationView.centerOffset = CGPoint(x: 0, y: -(annotationView.image!.size.height / 2))
        
        return annotationView
    }
    
    /**
     MKMapViewDelegate function, used when annotation is tapped to transition to the detail view
    */
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Delete pin, if "edit" mode is active
        if (editPinsButton.title == "Done") {
            
            if let annotation = view.annotation as? MyMKPointAnnotation {
                
                let location = annotation.location!
                
                // Delete images from cache and disk, if any
                if let photos = location.photos {
                    for photo in Array(photos) as! [Photo] {
                        Networking.imageStore.deleteImage(forKey: photo.photoID!)
                    }
                }
                
                mapView.removeAnnotation(annotation)
                CoreData.moc.delete(annotation.location!)
            }
            return
        }
        
        // Needed to remove focus from pin
        // Used when user comes back to map, to have no pins in focus
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "PinDetailControllerStoryboardID") as! PinDetailViewController
        
        // Pass the Core Data Locations instance associated with the selected pin
        vc.annotation = view.annotation as? MKPointAnnotation
        
        navigationItem.title = Constants.AppStrings.DetailViewControllerBackButtonText
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func gestureRecognizer(enable: Bool) {
        if enable {
            mapView.addGestureRecognizer(longPressGesture)
        } else {
            mapView.removeGestureRecognizer(longPressGesture)
        }
    }
    
    /**
     Adds new pin to the map and database, on user action.
     Used as a handler for LongPress event
    */
    func addPin(sender: UILongPressGestureRecognizer) {
        
        let coordinates: CLLocationCoordinate2D!
        
        if sender.state == UIGestureRecognizerState.began {
            
            // Gets coordinates for droped pin by converting from point of screen touched
            let point = sender.location(in: mapView)
            coordinates = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Creating and saving a location object
            let location = CoreData.saveLocationToDB(coordinates: coordinates)
            
            // Add new location to locations array
            locations?.append(location)
            
            // Create annotation and add it to map
            _ = MapController.createAnnotation(from: location)
            
        }
    }
    
    @IBAction func editPinsButtonAction(_ sender: Any) {
        
        let barButton = sender as? UIBarButtonItem
        
        if barButton?.title == "Edit" {
            // Change button text to "Done"
            barButton?.title = "Done"
            
            // Disable default map interactions
            gestureRecognizer(enable: false)
            
            // Show bottom label text on red background: "Tap Pins to Delete"
            mapViewBottomConstraint.constant = 40
            
            // If pin tapped, remove it from map
            
            // When "Done" button is pressed, commit change to DB
        } else {
            
            // "Done" button was pressed
            
            barButton?.title = "Edit"
            mapViewBottomConstraint.constant = 0
            gestureRecognizer(enable: true)
            CoreData.saveContext()
            
            
        }
        
    }
    
}

