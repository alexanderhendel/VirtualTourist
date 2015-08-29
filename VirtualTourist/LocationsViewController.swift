//
//  LocationsViewController.swift
//  VirtualTourist
//
//  Created by Hiro on 14.08.15.
//  Copyright © 2015 alexhendel. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationsViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    // variables / shared objects
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var fetchResultsController: NSFetchedResultsController?
    var currentPinIndexPath: NSIndexPath!
    
    // MARK: - IBOutlet
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // me is mapView delegate
        mapView.delegate = self
        
        // load the last map location from NSUserDefaults if available
        appDelegate.region = getMapRegionFromUserDefaults()
        
        if (appDelegate.region != nil) {
            // got complete region so show it on the map
            mapView.setRegion(appDelegate.region, animated: true)
        } else {
            // no complete region could be read from UserDefaults so make fresh one..
            appDelegate.region = MKCoordinateRegion()
        }
        
        reloadPinsFromPersistentStore()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        switch segue.identifier! {
            case "showDetailSegue":
                let destination = segue.destinationViewController as! PhotoAlbumViewController
                let selectedObject = self.fetchResultsController?.objectAtIndexPath(currentPinIndexPath) as! Pin
                destination.pin = selectedObject
            default:
                print("Unknown segue: \(segue.identifier)")
            }
    }
    
    // MARK: - MapKit delegate implementation
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // region changed so update the region var which will be stored in UserDefaults
        appDelegate.region.center.latitude = mapView.region.center.latitude
        appDelegate.region.center.longitude = mapView.region.center.longitude
        appDelegate.region.span.latitudeDelta = mapView.region.span.latitudeDelta
        appDelegate.region.span.longitudeDelta = mapView.region.span.longitudeDelta
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is CustomAnnoation {
            
            return CustomAnnoation.createAnnotationView(reuseIdentifier: "customPin", annotation: annotation)
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if newState == MKAnnotationViewDragState.Ending {
            let annotation = view.annotation
            print("annotation dropped at: \(annotation!.coordinate.latitude),\(annotation!.coordinate.longitude)")
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let annotation = view.annotation as? CustomAnnoation {
            
            // reset the current index
            currentPinIndexPath = nil
            
            // open the pin
            for pin in appDelegate.pinArray {
                
                if ((pin.latitude == annotation.coordinate.latitude) &&
                    (pin.longitude == annotation.coordinate.longitude)) {
                 
                    self.currentPinIndexPath = self.fetchResultsController?.indexPathForObject(pin)
                }
            }
            
            // see if index was found
            if (currentPinIndexPath != nil) {
                performSegueWithIdentifier("showDetailSegue", sender: self)
            } else {
                print("Could not find a coredata object represented by annotation: \(annotation)")
            }
        }
    }
    
    // MARK: - IBAction
    @IBAction func handleMapTap(recognizer: UITapGestureRecognizer) {
    
        // performSegueWithIdentifier("showDetailSegue", sender: self)
    }
    
    @IBAction func handleMapLongPress(sender: UILongPressGestureRecognizer) {

        // chekc for the state of the recognizer and drop the pin if the gesture ended
        if (sender.state == UIGestureRecognizerState.Ended) {
            
            // drop pin / add pin object to CoreData
            var point: CGPoint
            var location: CLLocationCoordinate2D
            
            point = sender.locationInView(mapView)
            location = mapView.convertPoint(point, toCoordinateFromView: mapView)
            
            // geocode the location to get locality name
            let geocoder = CLGeocoder()
            let pinLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            
            geocoder.reverseGeocodeLocation(pinLocation, completionHandler: {(placemarks, error) -> Void in
                
                if (error != nil) {
                    
                    print("Cant retrieve location name. \(error?.localizedDescription)")
                    return
                } else {
                    let placeArray = placemarks ?? []
                    
                    if (placeArray.count > 0) {
                        
                        let pm = placeArray[0] as CLPlacemark
                        
                        let newAnotation = CustomAnnoation(coordinate: location)
                        newAnotation.title = pm.locality
                        newAnotation.subtitle = pm.subLocality
                        
                        // make sure Annotation has a title and subtitle set
                        if (newAnotation.title == nil) {
                            newAnotation.title = "New Pin"
                        }
                        
                        if (newAnotation.subtitle == nil) {
                            newAnotation.subtitle = ""
                        }
                        
                        // save Pin to the persistent store
                        let error: NSError!
                        
                        let newPin = Pin(context: CoreDataStack.sharedInstance().managedObjectContext,
                                           title: newAnotation.title!,
                                        subtitle: newAnotation.subtitle!,
                                        latitude: newAnotation.coordinate.latitude,
                                       longitude: newAnotation.coordinate.longitude)
                        
                        error = newPin.save(CoreDataStack.sharedInstance().managedObjectContext)
                     
                        if (error == nil) {
                            
                            self.mapView.addAnnotation(newAnotation)
                            self.reloadPinsFromPersistentStore()
                        } else {
                            
                            let alert = Utils.alertWithoutAction(title: "Can't post pin.",
                                message: "The pin couldnt be saved to CoreData. \(error.localizedDescription)",
                                style: UIAlertControllerStyle.Alert)
                            self.presentViewController(alert, animated: true, completion: { } )
                        }
                    } else {
                        
                        print("Error processing geocoder response.")
                    }
                }
            })
        }
    }
    
    // MARK: - functions
    func reloadPinsFromPersistentStore() {
        
        // CoreData load pins from persistent store
        fetchResultsController = NSFetchedResultsController(fetchRequest: Pin.getFetchRequest(),
            managedObjectContext: CoreDataStack.sharedInstance().managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchResultsController?.delegate = self
        
        do {
            
            //try appDelegate.pinArray = CoreDataStack.sharedInstance().managedObjectContext.executeFetchRequest(Pin.getFetchRequest()) as! [Pin]
            
            try fetchResultsController?.performFetch()
            
            appDelegate.pinArray = fetchResultsController?.fetchedObjects as! [Pin]
            
            // fill map with loaded pins
            for pin in appDelegate.pinArray {
                
                let annotation = CustomAnnoation(coordinate: pin.coordinateFromLocationData())
                annotation.title = pin.title
                annotation.subtitle = pin.subtitle
                
                mapView.addAnnotation(annotation)
            }
            
        } catch let error as NSError {
            
            let alert = Utils.alertWithoutAction(title: "CoreData",
                message: "Couldnt load pins from CoreData. \(error.localizedDescription)",
                style: UIAlertControllerStyle.Alert)
            self.presentViewController(alert, animated: true, completion: { } )
        }
    }
    
    func getMapRegionFromUserDefaults() -> MKCoordinateRegion? {
    
        var myRegion: MKCoordinateRegion!
        
        // load the last map location from NSUserDefaults if available
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if (userDefaults.doubleForKey(AppDelegate.mapLocation.CenterLatKey) > 0) {
            
            if (userDefaults.doubleForKey(AppDelegate.mapLocation.CenterLonKey) > 0) {
                
                if (userDefaults.doubleForKey(AppDelegate.mapLocation.SpanLatKey) > 0) {
                    
                    if (userDefaults.doubleForKey(AppDelegate.mapLocation.SpanLonKey) > 0) {
                        
                        myRegion = MKCoordinateRegion()
                        
                        // all 4 values exist, now set them in region var
                        myRegion.center.latitude = userDefaults.doubleForKey(AppDelegate.mapLocation.CenterLatKey)
                        myRegion.center.longitude = userDefaults.doubleForKey(AppDelegate.mapLocation.CenterLonKey)
                        myRegion.span.latitudeDelta = userDefaults.doubleForKey(AppDelegate.mapLocation.SpanLatKey)
                        myRegion.span.longitudeDelta = userDefaults.doubleForKey(AppDelegate.mapLocation.SpanLonKey)
                    }
                }
            }
        }
        
        return myRegion
    }
}