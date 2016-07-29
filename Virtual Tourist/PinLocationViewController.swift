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
    
    var mapSet = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // Set map region only when the view is first loaded
        if !mapSet {
            if let region = NSUserDefaults.standardUserDefaults().objectForKey("mapRegion") as? [String: Double] {
                let center = CLLocationCoordinate2D(latitude: region["mapRegionCenterLatitude"]!, longitude: region["mapRegionCenterLongitude"]!)
                let span = MKCoordinateSpan(latitudeDelta: region["mapSpanLatitudeDelta"]!, longitudeDelta: region["mapSpanLongitudeDelta"]!)
                mapView.region = MKCoordinateRegion(center: center, span: span)
                mapSet = true
            }
        }
    }
    
    // MARK: NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
}

extension PinLocationViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let region = [
            "mapRegionCenterLatitude": mapView.region.center.latitude,
            "mapRegionCenterLongitude": mapView.region.center.longitude,
            "mapSpanLatitudeDelta": mapView.region.span.latitudeDelta,
            "mapSpanLongitudeDelta": mapView.region.span.longitudeDelta
        ]
        
        NSUserDefaults.standardUserDefaults().setObject(region, forKey: "mapRegion")
    }
}

extension PinLocationViewController: NSFetchedResultsControllerDelegate {
    
}