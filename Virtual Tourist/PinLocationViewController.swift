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
        
        // UIGestureRecognizer to drop pin when user presses on map
        let longpressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longpressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longpressRecognizer)
        
        processAnnotations()
    }
    
    // MARK: NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinate
            _ = Pin(latitude: annotation.coordinate.latitude, longitutde: annotation.coordinate.longitude, context: stack.context)
            mapView.addAnnotation(annotation)
            stack.save()
        }
    }
    
    // TODO: Funcation name?
    func processAnnotations() {
        fetchPins()

        var annotations = [MKPointAnnotation]()
        
        let pins = fetchedResultsController.fetchedObjects as? [Pin]
        
        if let pins = pins {
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = Double(pin.latitude)
                annotation.coordinate.longitude = Double(pin.longitude)
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
        }
    }
    
    func fetchPins() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // TODO: Change to alert
            print("Unable to fetch")
        }
    }
}

extension PinLocationViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
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