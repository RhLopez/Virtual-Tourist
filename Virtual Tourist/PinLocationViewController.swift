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
    @IBOutlet weak var mapEditLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapEditLabelBottomConstraint: NSLayoutConstraint!
    
    let stack = CoreDataStack.sharedInstance
    
    var mapSet = false
    
    var maxPageNumber: Int?
    var editMode: Bool?
    
    // MARK: UIViewController Lifecyle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editMode = false
        mapView.delegate = self
        
        // Set map region only when the view is first loaded
        if !mapSet {
            setMapRegion()
        }
        
        registerGestureRecognizer()
        processAnnotations()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
    }
    
    // Set map to coordinates previously used before user exited application
    func setMapRegion() {
        if let region = NSUserDefaults.standardUserDefaults().objectForKey("mapRegion") as? [String: Double] {
            let center = CLLocationCoordinate2D(latitude: region["mapRegionCenterLatitude"]!, longitude: region["mapRegionCenterLongitude"]!)
            let span = MKCoordinateSpan(latitudeDelta: region["mapSpanLatitudeDelta"]!, longitudeDelta: region["mapSpanLongitudeDelta"]!)
            mapView.region = MKCoordinateRegion(center: center, span: span)
            mapSet = true
        }
    }
    
    // UIGestureRecognizer to drop pin when user presses on map
    func registerGestureRecognizer() {
        let longpressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longpressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longpressRecognizer)
    }
    
    // Process pin drop when user presses on map
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
    
    // Show annotations that user has placed on map
    func processAnnotations() {
        var annotations = [MKPointAnnotation]()
        
        let pins = fetchPins()
    
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = Double(pin.latitude)
            annotation.coordinate.longitude = Double(pin.longitude)
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
    }
    
    func getPin(view: MKAnnotationView) -> Pin? {
        var pin: Pin?
        let annotation = view.annotation!
        
        let results = fetchPins()
        
        for fetchedPin in results {
            if annotation.coordinate.latitude == fetchedPin.latitude && annotation.coordinate.longitude == fetchedPin.longitude {
                pin = fetchedPin
                break
            }
        }
        
        return pin
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
                })
                self.maxPageNumber = maxPageNumber
            }
            else {
                AlertView.showAlert(self, title: "Alert", message: "Unable to process Photo request.\nPlease try again.")
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
    
    
    // MARK: NSFetchesRequest
    func fetchPins() -> [Pin] {
        var pins = [Pin]()
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
        do {
            try pins = stack.context.executeFetchRequest(fetchRequest) as! [Pin]
        } catch {
            AlertView.showAlert(self, title: "Alert", message: "Unable to retrieve pin information")
        }
        
        return pins
    }
}

extension PinLocationViewController: MKMapViewDelegate {
    // MARK: MKMapViewDelegate
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