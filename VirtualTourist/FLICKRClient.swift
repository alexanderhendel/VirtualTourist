//
//  FLICKRClient.swift
//  VirtualTourist
//
//  Created by Hiro on 14.08.15.
//  Copyright © 2015 alexhendel. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class FLICKRClient: NSObject {

    // MARK: - variable declarations
    var session: NSURLSession
    
    /// the last page of photos retrieved / downloaded
    var lastPage: Int
    
    /// the number of pages returned
    var maxPage: Int
    
    /// describes each flick (photo) and contains:
    /// - title
    /// - url
    /// - local path
    struct flick {
    
        var title: String
        var url_m: String
        var path: String
        
        init() {
        
            title = ""
            url_m = ""
            path = ""
        }
    }
    
    // MARK: - initializer
    override init() {
        
        // my own setup
        session = NSURLSession.sharedSession()
        lastPage = 1
        maxPage = 1
        
        // super init
        super.init()
    }
    
    // MARK: - functions
    
    /**
        Reset the last retrieved page and number of pages.
     */
    func refresh() {
    
        lastPage = 1
        maxPage = 1
    }
    
    /**
        Given a URL try to donwload the photo behind it. Result is handled by a completionHandler.

        :param: imageurl    The URL of the image.
        :param: completionHandler   Will return <NSError, UIImage> optionals.
     */
    func downloadPhotoWithURL(imageurl imageurl: NSURL, completionHandler: ((NSError?, UIImage?) -> Void)) {
        
        // get ready for the NSURL request
        var request: NSURLRequest!
        request = NSURLRequest(URL: imageurl)
        
        // search photos by location
        if (request != nil) {
            
            let task = session.dataTaskWithRequest(request!, completionHandler: {(data, response, downloadError) -> Void in
                
                // handle download error
                if let error = downloadError {
                    
                    print("couldnt finish download request: \(error.localizedDescription)")
                    
                    return completionHandler(error, nil)
                } else {
                    // parse the response the Swift 2.0 way
                    
                    if (data != nil) {
                        
                        if let image = UIImage(data: data!) {
                            
                            return completionHandler(nil, image)
                        } else {
                        
                            let error = NSError(domain: "download.error", code: 100, userInfo: ["localizedDescription": "conversion to image failed."])
                            return completionHandler(error, nil)
                        }
                    } else {
                        
                        let error = NSError(domain: "download.error", code: 200, userInfo: ["localizedDescription": "data download failed."])
                        return completionHandler(error, nil)
                    }
                }
            })
            
            task.resume()
        }
    }
    
    func photosSearchByLocationTask(latitude latitude: Double, longitude: Double, offset: Int, completionHandler: ((NSError?, [flick]?) -> Void)) {
        
        // get ready for the NSURL request
        var urlArgs = [
            "method": methods.flickrPhotosSearch,
            "api_key": constants.apiKey,
            "bbox": createBoundingBox(latitude: latitude, longitude: longitude),
            "safe_search": constants.extras.safeSearch,
            "extras": constants.extras.urlM,
            "format": constants.dataFormat.json,
            "nojsoncallback": constants.extras.noJsonCallback,
            "per_page": constants.extras.perPage
        ]
        
        if (offset > 0) {
        
            let newPage = lastPage + offset
            lastPage++
            
            if (newPage < maxPage) {
                urlArgs["page"] = String(newPage)
            } else {
                urlArgs["page"] = String(maxPage)
            }
            
            // print("maxPages: \(maxPage), newPage: \(newPage), lastPage: \(lastPage)")
        }
        
        let urlString = constants.baseURLSecure + escapedParameters(parameters: urlArgs)
        let url = NSURL(string: urlString)
        var request: NSURLRequest!
        
        if (url != nil) {
            request = NSURLRequest(URL: url!)
        }
      
        // search photos by location
        if (request != nil) {
            
            let task = session.dataTaskWithRequest(request!, completionHandler: {(data, response, downloadError) -> Void in
                
                // handle download error
                if let error = downloadError {
                    
                    print("couldnt finish download request: \(error)")
                } else {
                    // parse the response the Swift 2.0 way
                    do {
                        let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                        
                        if let photosDictionary = parsedResult.valueForKey("photos") as? [String: AnyObject] {
                            
                            // get the photos
                            var totalPhotosVal = 0
                            if let totalPhotos = photosDictionary["total"] as? String {
                                totalPhotosVal = (totalPhotos as NSString).integerValue
                            }
                            
                            if let totalPages = photosDictionary["pages"] {
                                self.maxPage = totalPages as! Int
                            }
                            
                            if totalPhotosVal > 0 {
                                
                                if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                    
                                    var photos = [flick]()
                                    
                                    for photo in photosArray {
                                    
                                        let photoDict = photo as [String: AnyObject]
                                        
                                        // get photo details
                                        var pic = flick()
                                        
                                        if let photoTitle = photoDict["title"] as? String {
                                            pic.title = photoTitle
                                        }
                                        if let photoUrl = photoDict["url_m"] as? String {
                                            pic.url_m = photoUrl
                                        }
                                        
                                        photos.append(pic)
                                    }
                                    
                                    if (photos.count > 0) {
                                    
                                        return completionHandler(nil, photos)
                                    } else {
                                    
                                        let err = NSError(domain: "error.parse", code: 100, userInfo: ["localizedDescription": "No photos found."])
                                        return completionHandler(err, nil)
                                    }
                                    
                                } else {
                                    
                                    let err = NSError(domain: "error.parse", code: 101, userInfo: ["localizedDescription": "No 'photo' keys found in \(photosDictionary)."])
                                    return completionHandler(err, nil)
                                }
                            } else {
                                
                                let err = NSError(domain: "error.parse", code: 102, userInfo: ["localizedDescription": "No 'pages' key found in \(photosDictionary)."])
                                return completionHandler(err, nil)
                            }
                        } else {

                            let err = NSError(domain: "error.parse", code: 103, userInfo: ["localizedDescription": "No 'photos' key found in \(parsedResult)."])
                            return completionHandler(err, nil)
                        }
                    } catch let error as NSError {
                        
                        print("parse error: \(error.description)")
                        return completionHandler(error, nil)
                    } catch {
                    
                        print("generic URLtask error")
                    }
                }
            })
            
            task.resume()
        }
    }
    
    // MARK: - private helper functions
    
    /**
        Creates a bounding box string from latitude & logitude values.
    
        :param: latitude    Latitude of the map location.
        :param: longitude   Longitude of the map location.
     */
    private func createBoundingBox(latitude latitude: Double, longitude: Double) -> String {
    
        let bottomLeftLon = max(longitude - constants.boundingBox.halfWidth,
                                constants.boundingBox.longitudeMin)
        
        let bottomLeftLat = max(latitude - constants.boundingBox.halfHeigt,
                                constants.boundingBox.latitudeMin)
        
        let topRightLon = min(longitude + constants.boundingBox.halfWidth,
                              constants.boundingBox.longitudeMax)
        
        let topRightLat = min(latitude + constants.boundingBox.halfHeigt,
                              constants.boundingBox.latitudeMax)
            
        // return the string
        return "\(bottomLeftLon),\(bottomLeftLat),\(topRightLon),\(topRightLat)"
    }
    
    /**
        Create escaped parameter string from dictionary.
    
        :param: parameters  A [String: AnyObject] dictionary with the parametrs to be escaped.
     */
    private func escapedParameters(parameters parameters: [String:AnyObject]) -> String {
    
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
}