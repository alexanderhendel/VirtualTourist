//
//  Pin.swift
//  VirtualTourist
//
//  Created by Hiro on 18.08.15.
//  Copyright © 2015 alexhendel. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)

class Pin: NSManagedObject {
    
    /**
        Default initializer.
    
        :param: context     The NSManagedObjectContext to store the Pin.
     */
    convenience init(context: NSManagedObjectContext) {
    
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /**
        Convenience initializer.
    
        :param: context     The NSManagedObjectContext to store the Pin.
        :param: title       The title of the Pin. Usually the location / city name.
        :param: subtitle    Optional the name of the locale / area.
        :param: latitude    The latitude of the location.
        :param: longitude   The longitude of the location.
    */
    convenience init(context: NSManagedObjectContext,
                       title: String,
                    subtitle: String! = nil,
                    latitude: Double,
                   longitude: Double) {
        // init
        self.init(context: context)
                    
        self.title = title
        if let sub = subtitle {
            self.subtitle = sub
        } else {
            self.subtitle = ""
        }
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /**
        Persist the Pin object instance.
    
        :param: context managedObjectContext
     */
    func save(context: NSManagedObjectContext) -> NSError? {
        
        var retErr: NSError!
        retErr = nil
        
        do {
            try context.save()
        } catch let e as NSError {
            retErr = e
            print("Failure to save context: \(e.localizedDescription)")
        }
        
        return retErr
    }
    
    /**
        Setup a CoreData FetchRequest for Pin objects.
    
        :returns: NSFetchRequest for Pins ready to go.
     */
    class func getFetchRequest() -> NSFetchRequest {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchBatchSize = 20
        fetchRequest.relationshipKeyPathsForPrefetching = ["photos"]
        
        return fetchRequest
    }
    
    /**
        Each Pin stores a latitude and longitude. This convenience function takes 
        the two values and returns a `CLLocationCoordinate2D` object.
    
        :returns: CLLocationCoordinate2D object from the Pin latitude & longitude.
     */
    func coordinateFromLocationData() -> CLLocationCoordinate2D {
    
        var coordinate: CLLocationCoordinate2D
        
        coordinate = kCLLocationCoordinate2DInvalid
        
        if let lat = self.latitude {
            if let lon = self.longitude {
            
                coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lon))
            }
        }
        
        return coordinate
    }
}
