//
//  CustomAnnotation.swift
//  VirtualTourist
//
//  Created by Hiro on 18.08.15.
//  Copyright © 2015 alexhendel. All rights reserved.
//

import Foundation
import MapKit

class CustomAnnoation: NSObject, MKAnnotation {

    var title: String?
    var subtitle: String?
    var locationName: String?
    
    let coordinate: CLLocationCoordinate2D
    
    init (coordinate: CLLocationCoordinate2D!) {
        
        // init coordinate
        if (coordinate != nil) {
            self.coordinate = coordinate
        } else {
            self.coordinate = kCLLocationCoordinate2DInvalid
        }
        
        super.init()
    }
    
    class func createAnnotationView(reuseIdentifier reuseIdentifier: String, annotation: MKAnnotation) -> MKPinAnnotationView {
        
        let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        if #available(iOS 9.0, *) {
            pinAnnotationView.pinTintColor = UIColor.blueColor()
        } else {
            pinAnnotationView.tintColor = UIColor.blueColor()
        }
        pinAnnotationView.draggable = true
        pinAnnotationView.canShowCallout = true
        pinAnnotationView.animatesDrop = true
        
        let infoButton = UIButton(type: UIButtonType.DetailDisclosure)
        infoButton.frame.size.width = 44
        infoButton.frame.size.height = 44
        
        pinAnnotationView.leftCalloutAccessoryView = infoButton
        
        return pinAnnotationView
    }
}