//
//  AppDelegateConstants.swift
//  VirtualTourist
//
//  Created by Hiro on 18.08.15.
//  Copyright © 2015 alexhendel. All rights reserved.
//

import Foundation

extension AppDelegate {

    // MARK: - constants
    
    /// the keys for storing the map location in NSUserDefaults
    struct mapLocation {
        static let CenterLatKey = "map.location.center.latitude"
        static let CenterLonKey = "map.location.center.longitude"
        static let SpanLatKey = "map.location.span.latitude"
        static let SpanLonKey = "map.location.span.longitude"
    }
}