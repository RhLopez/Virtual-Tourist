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

    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var maxPageNumber: Int?
    
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
        
        // TODO: Fix cell sizing
        let width = self.photoCollectionView.frame.size.width / 3.03
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
    
    func configureCell(cell: PhotoCollectionViewCell, indexPath: NSIndexPath) {
        cell.imageView.image = UIImage(named: "placeholder")
        cell.activityIndicator.startAnimating()
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.photo == nil {
                FlickrClient.sharedInstance.getImageFromURL(photo, completionHandlerForPhotoData: { (data) in
                    if let data = data {
                        self.stack.context.performBlock({
                        photo.photo = data
                        self.stack.save()
                    })
                    
                    let image = UIImage(data: data)
                    dispatch_async(dispatch_get_main_queue(), { 
                        cell.imageView.image = image
                        cell.activityIndicator.stopAnimating()
                    })
                }
            })
        } else {
            let image = UIImage(data: photo.photo!)
            cell.imageView.image = image
            cell.activityIndicator.stopAnimating()
        }
        
        if selectedIndexes.indexOf(indexPath) != nil {
            cell.imageView.alpha = 0.5
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    func updateButton() {
        if selectedIndexes.isEmpty {
            collectionButton.setTitle("New Collection", forState: .Normal)
        } else {
            collectionButton.setTitle("Remove Selected Photos", forState: .Normal)
        }
    }
    
    func deleteSelectedPhotos() {
        var photoToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photoToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photoToDelete {
            stack.context.deleteObject(photo)
        }
        
        stack.save()
        selectedIndexes = [NSIndexPath]()
    }
    
    @IBAction func newCollectionButtonPressed(sender: AnyObject) {
        if selectedIndexes.isEmpty {
            collectionButton.enabled = false
            let photos = fetchedResultsController.fetchedObjects as! [Photo]
            
            for photo in photos {
                fetchedResultsController.managedObjectContext.deleteObject(photo)
            }
            
            if maxPageNumber == nil {
                maxPageNumber = 1
            }

            FlickrClient.sharedInstance.imageURLRequestWithPage(pin, maxPageNumber: maxPageNumber) { (sucess, results, maxPageNumber) in
                if sucess {
                    self.stack.context.performBlock({ 
                        for urlString in results {
                            let photo = Photo(imageURL: urlString, context: self.stack.context)
                            photo.pin = self.pin
                        }
                        self.stack.save()
                    })
                    dispatch_async(dispatch_get_main_queue(), {
                        self.collectionButton.enabled = true
                    })
                    self.maxPageNumber = maxPageNumber
                }
                else {
                    // TODO: Change to Alert
                    print("There were no url strings")
                }
            }
        } else {
            deleteSelectedPhotos()
        }
        
        updateButton()
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

// MARK: UICollectionViewDelegate
extension PhotoCollectionViewContoller: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = photoCollectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        configureCell(cell, indexPath: indexPath)
        updateButton()
    }
}


// MARK: UICollectionViewDataSource
extension PhotoCollectionViewContoller: UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
}

// MARK: NSFetechedResultsControllerDelegate
extension PhotoCollectionViewContoller: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        photoCollectionView.performBatchUpdates({ 
            for indexPath in self.insertedIndexPaths {
                self.photoCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.photoCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            }, completion: nil)
    }
}

