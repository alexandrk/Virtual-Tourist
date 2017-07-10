//
//  PinDetailViewController.swift
//  Virtual Tourist
//
//  Created by Alexander on 7/6/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import UIKit
import MapKit

class PinDetailViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var selectedPin: MKPointAnnotation?
    var photosArray: [AnyObject]?
    fileprivate let numberOfItemsPerRow: CGFloat = 3
    fileprivate let sectionInsets = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
    
    private let reuseIdentifier = "flickrImageCell"
    private let regionRadius: CLLocationDistance = 1000 // 1km
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var mapViewHeightContraint: NSLayoutConstraint!
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create Pin and Center Map on It's Location
        if let selectedPin = selectedPin {
            mapView.addAnnotation(selectedPin)
            
            centerMapOnLocation(location: CLLocation(latitude: selectedPin.coordinate.latitude,
                                                     longitude: selectedPin.coordinate.longitude))
            
            // Requrst Images from Flickr API
            //noImagesLabel.text = "Retreiving Images From Flickr"
            //noImagesLabel.isEnabled = true
            Networking.sharedInstance.requestImagesForLocation(latitude: Double(selectedPin.coordinate.latitude),
                                                               longitude: Double(selectedPin.coordinate.longitude),
                                                               withPageNumber: 1,
                                                               completionHandler: completionHandlerForRequestImagesForLocation)
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    /**
    */
    func completionHandlerForRequestImagesForLocation(photosArray: AnyObject?, error: NSError?) {
        self.photosArray = photosArray as? [AnyObject]
        HelperFuncs.performUIUpdatesOnMain {
            self.collectionView.reloadData()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        var numberOfItems = 0
        
        // Set number of items to the length of photosArray
        if let photosArray = photosArray {
           numberOfItems = photosArray.count
        }
        
        if numberOfItems == 0 {
            noImagesLabel.isHidden = false
        }
        else {
            noImagesLabel.isHidden = true
        }
        return numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrImageCollectionViewCell
    
        /* GUARD: Configure the cell */
        guard let photoDictionary = photosArray?[indexPath.row] as? [String:AnyObject] else {
            print("Unable to convert photo from photosArray.\nIn \(#function) at line: \(#line)")
            return cell
        }
        
        /* GUARD: Does our photo have a key for 'url_m'? */
        guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
            print("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoDictionary).\nIn \(#function) at line: \(#line)")
            return cell
        }
        
        // if an image exists at the url, set the image //and title
        let imageURL = URL(string: imageUrlString)
        if let imageData = try? Data(contentsOf: imageURL!) {
            var imageView = cell.viewWithTag(100) as! UIImageView
            imageView.image = UIImage(data: imageData)
        } else {
            print("Image does not exist at \(imageURL).\nIn \(#function) at line: \(#line)")
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

extension PinDetailViewController: UICollectionViewDelegateFlowLayout {

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        mapViewHeightContraint.constant = view.frame.height / 4
        
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        
//        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
//            
//            let orient = UIApplication.shared.statusBarOrientation
//            
//            switch orient {
//                case .portrait:
//                    print("Portrait")
//                case .landscapeLeft,.landscapeRight :
//                    print("Landscape")
//                default:
//                    print("Anything But Portrait")
//            }
//            
//        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
//            self.collectionView.reloadData()
//            
//        })
//        super.viewWillTransition(to: size, with: coordinator)
//        
//    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (numberOfItemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / numberOfItemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
}
