//
//  AlertView.swift
//  Virtual Tourist
//
//  Created by Ramiro H. Lopez on 8/6/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class AlertView: NSObject {
    
    class func showAlert(view: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        dispatch_async(dispatch_get_main_queue()) { 
            view.presentViewController(alert, animated: true, completion: nil)
        }
    }
}
