//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Hiro on 18.08.15.
//  Copyright © 2015 alexhendel. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Pin {

    /// the Pin title, should be the city
    @NSManaged var title: String?
    
    /// the Pin subtitle, should be the locale name
    @NSManaged var subtitle: String?
    
    /// the latitude of the Pin
    @NSManaged var latitude: NSNumber?
    
    /// the longitude of the Pin
    @NSManaged var longitude: NSNumber?
    
    /// one-to-many relationship to the photos related to the Pin
    @NSManaged var photos: NSSet?
}
