//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Alexander on 7/6/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var longPressGesture: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set map view delegate with controller
        self.mapView.delegate = self
        
        // Gesture Recognizer
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPin))
        longPressGesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGesture)
    }

    // Used when annotation is tapped
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "PinDetailControllerStoryboardID") as! PinDetailViewController
        
        vc.selectedPin = view.annotation as? MKPointAnnotation
        
        navigationController?.pushViewController(vc, animated: true)
        
//        print(view.annotation?.title)
//        let geocoder = CLGeocoder()
//        let clLocation = CLLocation(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
//        geocoder.reverseGeocodeLocation(clLocation, completionHandler: { placemarks, error in
//            
//            if let placemark = placemarks?.first,
//            let addressDictionary = placemark.addressDictionary as? [String: AnyObject],
//            let formattedAddress = addressDictionary["FormattedAddressLines"] as? [String] {
//                print(formattedAddress.joined(separator: " "))
//            }
//            else {
//                print("Could not get formatted address from the location pin")
//            }
//            
//        })        
    }
    
    func addPin(sender: UILongPressGestureRecognizer) {
        
        let coordinates: CLLocationCoordinate2D!
        
        if sender.state == UIGestureRecognizerState.began {
            let point = sender.location(in: mapView)
            coordinates = mapView.convert(point, toCoordinateFrom: mapView)
            
            let alertVC = UIAlertController(title: "Please provide a new Pin title", message: nil, preferredStyle: .alert)
            alertVC.addTextField{(textField) in
                textField.placeholder = "Pin Title"
            }
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action: UIAlertAction) in
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinates
                annotation.title = "Default Title"
                
                if let textField = alertVC.textFields?.first {
                    if let newTitle = textField.text {
                        annotation.title = newTitle
                    }
                }
                
                self.mapView.addAnnotation(annotation)
            }))
            
            self.present(alertVC, animated: true, completion: nil)
            
        }
        else {
            print("sender.state: \(sender.state.rawValue)")
        }
    }
}

