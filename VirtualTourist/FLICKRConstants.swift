//
//  FLICKRConstants.swift
//  VirtualTourist
//
//  Created by Hiro on 14.08.15.
//  Copyright © 2015 alexhendel. All rights reserved.
//

extension FLICKRClient {

    // MARK: - constants
    struct constants {
    
        static let apiKey = "ENTER_YOUR_API_KEY_HERE"
        static let baseURLSecure = "https://api.flickr.com/services/rest/"
        
        struct dataFormat {
        
            static let json = "json"
        }
        
        struct extras {

            static let urlM = "url_m"
            static let noJsonCallback = "1"
            static let safeSearch = "1"
            static let perPage = "25"
        }
        
        struct boundingBox {
        
            static let halfWidth = 1.0
            static let halfHeigt = 1.0
            static let latitudeMin = -90.0
            static let latitudeMax = 90.0
            static let longitudeMin = -180.0
            static let longitudeMax = 180.0
        }
    }
    
    // MARK: - API methods
    struct methods {
    
        static let flickrPhotosSearch = "flickr.photos.search"
    }
}
