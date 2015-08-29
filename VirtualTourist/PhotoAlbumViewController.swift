//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Hiro on 14.08.15.
//  Copyright © 2015 alexhendel. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate {
    
    let docPath = Utils.applicationDocumentsDirectory() as String + "/"
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var fetchResultsController: NSFetchedResultsController?
    
    // this will store the pin CoreData object passed from the LocationsViewController
    weak var pin: Pin!
    
    // MARK: - IBOutlet
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    
    // MARK: - ViewController
    override func viewDidLoad() {        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view
        mapView.delegate = self
        photoCollection.dataSource = self
        photoCollection.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // reset the last viewed bage
        appDelegate.api.refresh()
        
        // update the map with the current annotation location
        if let lat = pin.latitude {
            if let lon = pin.longitude {
                
                let annotationPin = MKPointAnnotation()
                
                annotationPin.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lon))
                mapView.addAnnotation(annotationPin)
                
                centerMapOnLocation(CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lon)))
                
                fetchAllPhotosForPin()
                
                // only try to get photos if the current pin has none assigned yet
                // if let count = pin.photos?.count {
                if let count = fetchResultsController?.fetchedObjects?.count {
                    if count <= 0 {
                        
                        getPhotosFromFlickr(0, latitude: lat as Double, longitude: lon as Double)
                    }
                }
                
                photoCollection.reloadData()
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if (fetchResultsController?.fetchedObjects?.count != nil) {
            
            let photo = fetchResultsController?.objectAtIndexPath(indexPath) as! Photo?
            removePhotoFromPin(photo)
            photoCollection.deleteItemsAtIndexPaths([indexPath])
        }
        
        // now refresh teh fetchResultsController
        fetchAllPhotosForPin()
        
        // refresh the collection view
        photoCollection.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        //let count = pin.photos?.count
        fetchAllPhotosForPin()
        
        let count = fetchResultsController?.fetchedObjects?.count
        if count != nil {
            return count!
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // dequeue a photoCell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! CustomCollectionViewCell
        
        // tint the cell grey to inform the user there are images before image download is complete
        cell.backgroundColor = UIColor.lightGrayColor()
        
        if let photo: Photo = fetchResultsController?.objectAtIndexPath(indexPath) as? Photo {
        
            // if there is an image then download it - else try to download from the image URL
            if (photo.path != nil) {
                
                let img = UIImage(contentsOfFile: (docPath as String) + photo.path!)
                cell.imageView.image = img
            } else {
                
                cell.activityIndicator.startAnimating()
                
                // now start the download
                appDelegate.api.downloadPhotoWithURL(imageurl: NSURL(string: photo.url_m!)!, completionHandler: { error, imageData -> Void in
                    
                    cell.activityIndicator.stopAnimating()
                    
                    if (error == nil) {
                        // no error so lets parse the data
                        if (imageData != nil) {
                            
                            let docID = NSUUID().UUIDString + ".png"        // unique file name
                            let destinationPath = self.docPath + docID           // put it all together
                            
                            // write the file to the destination
                            let writeOpt = NSDataWritingOptions.DataWritingFileProtectionNone
                            let data = UIImagePNGRepresentation(imageData!)
                            
                            do {
                                try data!.writeToFile(destinationPath, options: writeOpt)
                            
                                // store the destination path in the photo object
                                photo.path = docID
                                photo.save(CoreDataStack.sharedInstance().managedObjectContext)
                            
                                dispatch_async(dispatch_get_main_queue(), {
                                    cell.imageView.image = UIImage(contentsOfFile: self.docPath + photo.path!)
                                })
                            } catch {
                                fatalError("saving the file \(docID) failed with error: \(error)")
                            }
                        }
                    } else {
                        
                        // got a error so do something
                        print("error retrieving the images: \(error?.localizedDescription)")
                    }
                })
            }
        }
        
        return cell
    }
    
    // MARK: - MapView Delegate Protocol
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {

        let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "locationPin")
            
        if #available(iOS 9.0, *) {
            pinAnnotationView.pinTintColor = UIColor.purpleColor()
        } else {
            pinAnnotationView.tintColor = UIColor.purpleColor()
        }
        pinAnnotationView.draggable = false
        pinAnnotationView.canShowCallout = false
        pinAnnotationView.animatesDrop = true
        
        return pinAnnotationView
    }
    
    // MARK: - functions
    
    /**
        Center the mapView on the location of the current pin.
    
        :param: location    The location data of the pin as `CLLocation` object.
     */
    func centerMapOnLocation(location: CLLocation) {
        
        let regionRadius = 2000.0
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func getPhotosFromFlickr(offset: Int, latitude: Double, longitude: Double) {
    
        // get photos for the location
        appDelegate.api.photosSearchByLocationTask(latitude: latitude, longitude: longitude, offset: offset, completionHandler: { error, data -> Void in
            
            if (error == nil) {
                // no error so lets parse the data
                if (data != nil) {
                    for imgData in data! {
                        // save Photo to the persistent store
                        let error: NSError!
                        
                        let newPhoto = Photo(context: CoreDataStack.sharedInstance().managedObjectContext,
                                               title: imgData.title,
                                               url_m: imgData.url_m,
                                                 pin: self.pin)
                        
                        error = newPhoto.save(CoreDataStack.sharedInstance().managedObjectContext)
                        
                        if (error == nil) {
                            //self.reloadPinsFromPersistentStore()
                        } else {
                            print("Fatal Error: couldn't persist photo.")
                        }
                    }
                    
                    // update the collection in main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.photoCollection.reloadData()
                    })
                }
            } else {
                print("error retrieving the images: \(error?.localizedDescription)")
            }
        })
    }
    
    func fetchAllPhotosForPin() {
        // CoreData load pins from persistent store
        let fetch = Photo.getFetchRequest()
        fetch.predicate = NSPredicate(format: "pin == %@", pin)
        
        fetchResultsController = nil      // reset
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetch,
            managedObjectContext: CoreDataStack.sharedInstance().managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchResultsController?.delegate = self
        
        do {
            
            try fetchResultsController?.performFetch()
            
        } catch let error as NSError {
            
            let alert = Utils.alertWithoutAction(title: "CoreData",
                message: "Couldnt load photos for Pin. \(error.localizedDescription)",
                style: UIAlertControllerStyle.Alert)
            self.presentViewController(alert, animated: true, completion: { } )
        }
    }
    
    func removePhotoFromPin(photo: Photo!) {
        
        if (photo != nil) {
            if (photo!.path != nil) {
                let path = docPath + photo!.path!
                
                let fm = NSFileManager()
                do {
                    try fm.removeItemAtPath(path)
                } catch {
                    fatalError("Couldn't remove '\(path)'. \(error)")
                }
            }
            
            CoreDataStack.sharedInstance().managedObjectContext.deleteObject(photo!)
            CoreDataStack.sharedInstance().saveContext()
        }
    }
    
    func removeAllPhotosFromPin() {

        if (fetchResultsController?.fetchedObjects?.count != nil) {
            
            let photos = fetchResultsController?.fetchedObjects as! [Photo]?
            
            if (photos != nil) {
                for photo in photos! {
                    
                    removePhotoFromPin(photo)
                }
            }
        }
    }
    
    // MARK: - IBActions
    @IBAction func newCollection(sender: AnyObject) {
        
        // since the user wants a new collection - clear the old images
        removeAllPhotosFromPin()
        
        // now refresh teh fetchResultsController
        fetchAllPhotosForPin()
        
        // refresh the collection view
        photoCollection.reloadData()
        
        // now go get a fresh set of images
        if let lat = pin.latitude {
            if let lon = pin.longitude {
                
                let offset = 1
                getPhotosFromFlickr(offset, latitude: lat as Double, longitude: lon as Double)
            }
        }
    }
}