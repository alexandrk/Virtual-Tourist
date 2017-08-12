//
//  MyMKPointAnnotation.swift
//  Virtual Tourist
//
//  Adds a property to store Location object (referenced in different view controllers)
//
//  Created by Alexander on 8/4/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import MapKit
import CoreData


class MyMKPointAnnotation: MKPointAnnotation {

    var location: Location?
    
}
