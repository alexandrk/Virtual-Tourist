//
//  Constants.swift
//  Virtual Tourist
//
//  Created by Alexander Kazakov on 7/07/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

// MARK: - Constants

struct Constants {
    
    struct AppStrings {
        static let AppName = "Virtual Tourist"
        static let DetailViewControllerBackButtonText = "OK"
        static let NewCollectionButtonTitle = "New Collection"
        static let RemoveSelectedPicturesButtonTitle = "Remove Selected Pictures"
    }
    
    // MARK: Flickr
    struct Flickr {
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
        static let BaseURLString = "https://api.flickr.com/services/rest"
    }
    
    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let PageNumber = "page"
        static let NumberOfPhotosPerPage = "per_page"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"

        static let APIKey = "c075abbcb8fdd34e36aea3602318bced"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */

        static let UseSafeSearch = "1"
        static let NumberOfPhotosPerPage = "30"
        
        static let SmallURL = "url_s"
        static let MediumURL = "url_m"
        static let LargeURL = "url_l"
        static let OriginalURL = "url_o"
        static let DateTaken = "date_taken"
        static let Tags = "tags"
        static let Views = "views"
    }
    
    // MARK: Flickr Response Keys
    struct FlickrResponseKeys {
        static let PhotoID = "id"
        static let SmallURL = "url_s"
        static let MediumURL = "url_m"
        static let LargeURL = "url_l"
        static let OriginalURL = "url_o"
        static let DateTaken = "datetaken"
        static let Tags = "tags"
        static let Owner = "owner"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let PageNumber = "page"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
    
    // MARK: CoreData String Values
    struct CoreDataValues {
        static let PinsPersistentContainer = "PinsAndPhotos"
        static let NSFetchRequestSortProperty = "label"
    }
    
    // MARK: Detail View Controller Values
    struct DetailVCValues {
        static let CustomCollectionCellName = "flickrImageCell"
        static let AnnotationViewIdentifier = "myAnnotationView"
    }
    
}
