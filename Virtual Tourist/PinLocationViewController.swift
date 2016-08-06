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
    
    var maxPageNumber: Int?
    var editMode: Bool?
    @IBOutlet weak var mapEditLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapEditLabelBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editMode = false
        
        mapView.delegate = self
        
        // Set map region only when the view is first loaded
        if !mapSet {
            setMapRegion()
        }
        
        // UIGestureRecognizer to drop pin when user presses on map
        let longpressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longpressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longpressRecognizer)
        
        processAnnotations()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
    }
    
    func setMapRegion() {
        if let region = NSUserDefaults.standardUserDefaults().objectForKey("mapRegion") as? [String: Double] {
            let center = CLLocationCoordinate2D(latitude: region["mapRegionCenterLatitude"]!, longitude: region["mapRegionCenterLongitude"]!)
            let span = MKCoordinateSpan(latitudeDelta: region["mapSpanLatitudeDelta"]!, longitudeDelta: region["mapSpanLongitudeDelta"]!)
            mapView.region = MKCoordinateRegion(center: center, span: span)
            mapSet = true
        }
    }
    
    func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinate
            let pin = Pin(latitude: annotation.coordinate.latitude, longitutde: annotation.coordinate.longitude, context: stack.context)
            mapView.addAnnotation(annotation)
            stack.save()
            startImageUrlRequest(pin)
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
    
    func getPin(view: MKAnnotationView) -> Pin? {
        var pin: Pin?
        let annotation = view.annotation!
        
        fetchPins()
        
        let results = fetchedResultsController.fetchedObjects as? [Pin]
        
        for fetchedPin in results! {
            if annotation.coordinate.latitude == fetchedPin.latitude && annotation.coordinate.longitude == fetchedPin.longitude {
                pin = fetchedPin
                break
            }
        }
        
        return pin
    }
    
    func fetchPins() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // TODO: Change to alert
            print("Unable to fetch")
        }
    }
    
    // Get image urls to be used in PhotoCollectionViewController
    func startImageUrlRequest(pin: Pin) {
        FlickrClient.sharedInstance.startImageUrlRequest(pin) { (sucess, results, maxPageNumber) in
            if sucess {
                self.stack.context.performBlock({ 
                    for urlString in results {
                        let photo = Photo(imageURL: urlString, context: self.stack.context)
                        photo.pin = pin
                    }
                    self.stack.save()
                    print(pin.photos?.count)
                })
                self.maxPageNumber = maxPageNumber
            }
            else {
                // TODO: Change to Alert
                print("There were no url strings")
            }
        }
    }
    
    @IBAction func editButtonPressed(sender: AnyObject) {
        if editMode == false {
            UIView.animateWithDuration(0.25, animations: {
                self.mapView.frame.origin.y = (self.getLabelHeight() * -1)
            })
            editButton.title = "Done"
            editMode = true
        } else {
            UIView.animateWithDuration(0.25, animations: {
                self.mapView.frame.origin.y = 0
            })
            editMode = false
            editButton.title = "Edit"
        }
    }
    
    func getLabelHeight() -> CGFloat {
        return mapEditLabel.frame.height
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


// MARK: MKMapViewDelegate
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
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if editMode == true {
            stack.context.deleteObject(getPin(view)!)
            self.mapView.removeAnnotation(view.annotation!)
            stack.save()
        } else {
            let detailViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoCollectionViewController") as! PhotoCollectionViewContoller
            
            detailViewController.pin = getPin(view)
            detailViewController.maxPageNumber = maxPageNumber
            mapView.deselectAnnotation(view.annotation, animated: true)
            navigationController?.pushViewController(detailViewController, animated: true)
        }
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

// MARK: NSFetchedResultsControllerDelegate
extension PinLocationViewController: NSFetchedResultsControllerDelegate {
    
}