//
//  Photo+CoreDataProperties.swift
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

extension Photo {

    /// photo title
    @NSManaged var title: String?
    
    /// the Flickr URL of the photo
    @NSManaged var url_m: String?
    
    /// the path to the photo in the App Documents directory
    @NSManaged var path: String?
    
    /// reverse relationship of the photo to the Pin
    @NSManaged var pin: Pin?
}
