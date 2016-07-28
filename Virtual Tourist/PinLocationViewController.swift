//
//  PinLocationViewController.swift
//  Virtual Tourist
//
//  Created by Ramiro H. Lopez on 7/27/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PinLocationViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let stack = CoreDataStack.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
    }
    
    // MARK: NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
        let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        
        return fetchResultsController
    }()
}

extension PinLocationViewController: MKMapViewDelegate {
    
}

extension PinLocationViewController: NSFetchedResultsControllerDelegate {
    
}