//
//  PinDetailViewController.swift
//  Virtual Tourist
//
//  Created by Alexander on 7/6/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PinDetailViewController: UIViewController,
                               UICollectionViewDelegate,
                               UICollectionViewDataSource,
                               NSFetchedResultsControllerDelegate {

    fileprivate let numberOfItemsPerRow: CGFloat = 3
    fileprivate let sectionInsets = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
    var photos = [Photo]()
    fileprivate var selectedPhotosIndexPaths = [IndexPath]()
    fileprivate var selectedPhotos = [Photo]()
    
    static var location: Location!
    var annotation: MKPointAnnotation!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var mapViewHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var newCollectionBtn: UIButton!
    @IBOutlet weak var removeSelectedBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PinDetailViewController.location = (annotation as! MyMKPointAnnotation).location
        
        collectionView.allowsMultipleSelection = true
        
        // Setting reference to mapView for use in Map Helper controller
        MapController.mapViewReference = mapView
        
        // Add annotation to map and center map on it
        mapView.addAnnotation(annotation)
        MapController.centerMapOnLocation(coordinate: annotation.coordinate)
        
        // Disable map for user interaction
        mapView.isUserInteractionEnabled = false
        
        // Requrst Images from Flickr API
        getImagesForSelectedPin()
    }

    /**
     Gets images from database. If no images in DB, gets them from Flickr API
    */
    func getImagesForSelectedPin() {
        
        // If current location has photos, uses them
        if let locationPhotos = PinDetailViewController.location?.photos, locationPhotos.count > 0{
            photos = Array(locationPhotos) as! [Photo]
            collectionView.reloadData()
        }
        // Sends a Flickr request for images, based on current location coordinates data
        else
        {
            processNewPicturesRequest()
        }
    }
    
    // MARK: UICollectionViewDataSource

    /**
     collectionView numberOfItemsInSection datasource delegate
    */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    /**
     collectionView cellForItemAt datasource delegate
     */
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.DetailVCValues.CustomCollectionCellName, for: indexPath) as! FlickrImageCollectionViewCell
        return cell
    }

    // MARK: UICollectionViewDelegate

    /**
     Delegate method, that is called when the cell is about to be displayed in the collectionView
    */
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        
        let photo = photos[indexPath.row]
        
        // Get the image to be displayed in the cell
        Networking.sharedInstance.fetchImage(for: photo) {
            (result) -> Void in
            
            // The index path for the photo might have changed between the
            // time the request started and finished, so find the most recent
            // index path
            guard let photoIndex = self.photos.index(of: photo),
                case let .success(image) = result else {
                    return
            }
            let photoIndexPath = IndexPath(item: photoIndex, section: 0)
            
            print("photoIndexPath: \(photoIndexPath)")
            
            
            
            // When request finishes, only update the cell if it is still visible
            // Note: cellForItem returns VISIBLE cell object at the specified index path
            if let cell = collectionView.cellForItem(at: photoIndexPath) as? FlickrImageCollectionViewCell {
                cell.update(with: image)
            }
        }
        
    }
    
    /**
     Delegate method that is called when the cell is clicked (selected)
    */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Add indexPath of selected collection element to selected array
        selectedPhotosIndexPaths.append(indexPath)
        
        isRemoveItemsEnabled()

    }
    
    /**
     Delegate method that is called when the cell is deselected
    */
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        // Locates and Removes an item from selectedPhotosIndexPaths array
        let index = selectedPhotosIndexPaths.index(of: indexPath)
        if let index = index {
            selectedPhotosIndexPaths.remove(at: index)
        }
        
        isRemoveItemsEnabled()
    }
    
    /**
     Buttons click processor for "New Collection" and "Remove Selected Pictures" buttons
    */
    @IBAction func actionButtonPress(_ sender: Any) {
        let btn = sender as! UIButton
        
        if btn.currentTitle! == Constants.AppStrings.NewCollectionButtonTitle {
            
            btn.isEnabled = false
            loadNewCollectionOfImages {
                btn.isEnabled = true
            }
        }
        
        if btn.currentTitle! == Constants.AppStrings.RemoveSelectedPicturesButtonTitle {
            
            removeSelectedPictures()
            
        }
    }

    /**
     Handles the new collection request
    */
    private func loadNewCollectionOfImages(completionHandler: @escaping () -> Void) {
        
        // 0. Get page number for the current Flickr image set
        let currentPageNumber = PinDetailViewController.location.photoPageNumber
        let nextPageNumber = currentPageNumber + 1
        
        for photo in photos {
            // 1. Remove Images from Core Data
            CoreData.moc.delete(photo)
            
            // 2. Remove files from cache and filesystem
            // Check if file is there, before deleting
            //Networking.imageStore.deleteImage(forKey: photo.photoID!)
        }
        
        // 3. Remove Images from photos array
        photos.removeAll()
        
        // 4. Remove Images from collection view
        collectionView.reloadData()
        
        // 5. Save to CoreData
        CoreData.saveContext()
        
        // Request new items with new page number
        let extraParams = [Constants.FlickrParameterKeys.PageNumber: String(nextPageNumber)]
        processNewPicturesRequest(extraRequrstParameters: extraParams) {
            completionHandler()
        }
    }
    
    /**
     Handles the processing on a new Flickr request for pictures
    */
    func processNewPicturesRequest(extraRequrstParameters: [String: String] = [String:String](),
                                   completionHandler: (() -> Void)? = nil) {
        
        let latitude = PinDetailViewController.location.latitude
        let longitude = PinDetailViewController.location.longitude
        
        Networking.sharedInstance.fetchFlickrPhotosForLocation(
            lat: latitude,
            long: longitude,
            extraRequrstParameters: extraRequrstParameters) { result in
                                                                
            switch result {
            case let .success(photos):
                self.photos = photos
            case .failure:
                self.photos.removeAll()
            }
            
            OperationQueue.main.addOperation {
                self.collectionView.reloadData()
                self.toggleNoImagesLabel(numberOfImages: self.photos.count)
                
                if let completionHandler = completionHandler {
                    completionHandler()
                }
            }
        }
    }
    
    /**
     Handles the removal of selected pictures
    */
    func removeSelectedPictures() {
        // Sort selected photos indexPaths in descending order
        // This is necessary to avoid index out of bounds exception
        selectedPhotosIndexPaths = selectedPhotosIndexPaths.sorted { element1, element2 in
            return element1 > element2
        }
        
        // Loops through all the indexPaths for selected cells
        for indexPath in selectedPhotosIndexPaths {
            
            // 1. Remove Images from photos array
            let photo = photos.remove(at: indexPath.row)
            
            // 2. Remove Images from Core Data
            CoreData.moc.delete(photo)
            
            // 3. Remove files from cache and filesystem
            //Networking.imageStore.deleteImage(forKey: photo.photoID!)
            
        }
        
        // 4. Remove Images from collection view (should automatically redraw the collection)
        collectionView.deleteItems(at: selectedPhotosIndexPaths)
        
        // 5. Clear selected photos indexPath array
        selectedPhotosIndexPaths = []
        
        // 6. Save to CoreData
        CoreData.saveContext()
        
        // Toggle buttons [New Collection | Remove Selected Pictures]
        isRemoveItemsEnabled()
    }
    
    /**
     Toggles action buttons, based on the fact if the cells are selected
    */
    private func isRemoveItemsEnabled() {
        if selectedPhotosIndexPaths.count > 0 {
            newCollectionBtn.isHidden = true
            removeSelectedBtn.isHidden = false
        }
        else {
            newCollectionBtn.isHidden = false
            removeSelectedBtn.isHidden = true
        }
    }
    
    /**
     Shows no images label, if no images are available for the pin
    */
    private func toggleNoImagesLabel(numberOfImages: Int) {
        if (numberOfImages == 0) {
            noImagesLabel.isHidden = false
        }
        else {
            noImagesLabel.isHidden = true
        }
    }
    
}

/**
 Extension for flow layout with auto-adjustable cell sizes
*/
extension PinDetailViewController: UICollectionViewDelegateFlowLayout {

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Make mapView size a quarter of the screen
        mapViewHeightContraint.constant = view.frame.height / 4
        
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
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
