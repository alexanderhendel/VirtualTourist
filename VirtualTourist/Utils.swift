//
//  Utils.swift
//  VirtualTourist
//
//  Created by Hiro on 19.08.15.
//  Copyright © 2015 alexhendel. All rights reserved.
//

import Foundation
import UIKit

struct Utils {

    static func alertWithoutAction(title title: String, message: String, style: UIAlertControllerStyle) -> UIAlertController {
    
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: "OK", style: .Default) { _ in }
        
        alert.addAction(action)
        
        return alert
    }
    
    /// the application Documents directory
    static func applicationDocumentsDirectory() -> NSString {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        
        return documentsPath
    }
}