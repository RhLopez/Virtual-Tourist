//
//  PhotoCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Ramiro H. Lopez on 7/27/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoCollectionViewContoller: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var collectionButton: UIButton!
    
    var pin: Pin!
    let stack = CoreDataStack.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPhotos()
        showPin()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 0.5
        
        let width = self.photoCollectionView.frame.size.width / 3
        layout.itemSize = CGSize(width: width, height: width)
        photoCollectionView.collectionViewLayout = layout
    }
    
    // Process pin to show in mapView
    func showPin() {
        let pinAnnotation = MKPointAnnotation()
        pinAnnotation.coordinate.latitude = Double(pin.latitude)
        pinAnnotation.coordinate.longitude = Double(pin.longitude)
        let region = MKCoordinateRegionMakeWithDistance(pinAnnotation.coordinate, 2500, 2500)
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(pinAnnotation)
    }
    
    func fetchPhotos() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // TODO: Change to alert
            print("Unable to fetch photos")
        }
    }
    
    // MARK: NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        let predicate = NSPredicate(format: "pin = %@", self.pin)
        fetchRequest.predicate = predicate
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
}

// MARK: NSFetechedResultsControllerDelegate
extension PhotoCollectionViewContoller: NSFetchedResultsControllerDelegate {
    
}
