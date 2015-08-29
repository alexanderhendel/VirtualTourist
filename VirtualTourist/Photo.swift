//
//  Photo.swift
//  VirtualTourist
//
//  Created by Hiro on 18.08.15.
//  Copyright © 2015 alexhendel. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)

class Photo: NSManagedObject {

    /**
        Default initializer.
    
        :param: context     The NSManagedObjectContext to store the Pin.
    */
    convenience init(context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /**
        Convenience initializer.
    
        :param: context     The NSManagedObjectContext to store the Pin.
        :param: title       The title of the photo.
        :param: url_m       The Flickr URL of the photo.
        :param: path        Optional path of the photo in the Apps Documents directory. Path might be nil if the photo isn't downloaded yet.
        :param: pin         The Pin this photo is related to.
    */
    convenience init(context: NSManagedObjectContext,
                       title: String,
                       url_m: String,
                        path: String! = nil,
                         pin: Pin) {
            
            // init
            self.init(context: context)
                            
            self.title = title
            self.url_m = url_m
            if path != nil {
                self.path = path
            }
            self.pin = pin
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
        Setup a CoreData FetchRequest for Photo objects.
        
        :returns: NSFetchRequest for a Photo ready to go.
    */
    class func getFetchRequest() -> NSFetchRequest {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchBatchSize = 20
        // fetchRequest.shouldRefreshRefetchedObjects = true
        fetchRequest.relationshipKeyPathsForPrefetching = ["pin"]
        
        return fetchRequest
    }
}
