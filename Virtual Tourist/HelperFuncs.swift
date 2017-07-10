//
//  HelperFuncs.swift
//  OnTheMap
//
//  Created by Alexander on 5/15/17.
//  Copyright © 2017 Dictality. All rights reserved.
//

import Foundation
import UIKit

class HelperFuncs {

    /**
        Performs UI updates on Main (used in async calls)
     */
    static func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }

    static func showAlert(_ controller : UIViewController, message : String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        
        HelperFuncs.performUIUpdatesOnMain {
            controller.present(alert, animated: true, completion: nil)
        }
    }
    
}
