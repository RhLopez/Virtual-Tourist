//
//  FlickrConvinience.swift
//  Virtual Tourist
//
//  Created by Ramiro H. Lopez on 7/29/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    func startImageUrlRequest(pin: Pin, completionHandlerForUrlRequest: (success: Bool, results: [String]!, maxPageNumber: Int!) -> Void) {
        
        let parameters = [
            Constants.ParameterKeys.Method: Constants.ParameterValues.SearchMethod,
            Constants.ParameterKeys.APIKey: Constants.ParameterValues.APIKey,
            Constants.ParameterKeys.Latitude: pin.latitude,
            Constants.ParameterKeys.Longitude: pin.longitude,
            Constants.ParameterKeys.Extras: Constants.ParameterValues.MediumURL,
            Constants.ParameterKeys.Format: Constants.ParameterValues.JSONFormat,
            Constants.ParameterKeys.NoJSONCallBack: Constants.ParameterValues.DisableJSONCallback,
            Constants.ParameterKeys.PerPage: Constants.ParameterValues.PerPageLimit
        ]
        
        taskForGetMethod(parameters) { (sucess, data) in
            if sucess {
                self.getPhotoDictionary(data, completionHandlerForPhotoDictionary: { (success, dictionary) in
                    if sucess {
                        self.parseFlickrImageUrl(dictionary, completionHandlerForParseImageUrl: completionHandlerForUrlRequest)
                    }
                })
            }
        }
    }
    
    func imageURLRequestWithPage(pin: Pin, maxPageNumber: Int!, completionHandlerForRequestWithPage: (success: Bool, results: [String]!, maxPageNumber: Int!) -> Void) {
        var randomPage: Int
        
        if maxPageNumber > 1 && maxPageNumber < 190 {
            randomPage = Int(arc4random_uniform(UInt32(maxPageNumber)))
        } else if maxPageNumber > 191 {
            randomPage = Int(arc4random_uniform(UInt32(191)))
        } else {
            randomPage = maxPageNumber
        }
        print(maxPageNumber)
        print(randomPage)
        
        let parameters = [
            Constants.ParameterKeys.Method: Constants.ParameterValues.SearchMethod,
            Constants.ParameterKeys.APIKey: Constants.ParameterValues.APIKey,
            Constants.ParameterKeys.Latitude: pin.latitude,
            Constants.ParameterKeys.Longitude: pin.longitude,
            Constants.ParameterKeys.Extras: Constants.ParameterValues.MediumURL,
            Constants.ParameterKeys.Format: Constants.ParameterValues.JSONFormat,
            Constants.ParameterKeys.NoJSONCallBack: Constants.ParameterValues.DisableJSONCallback,
            Constants.ParameterKeys.PerPage: Constants.ParameterValues.PerPageLimit,
            Constants.ParameterKeys.Page: randomPage
        ]
        
        taskForGetMethod(parameters) { (success, data) in
            if success {
                self.getPhotoDictionary(data, completionHandlerForPhotoDictionary: { (success, dictionary) in
                    if success {
                        self.parseFlickrImageUrl(dictionary, completionHandlerForParseImageUrl: completionHandlerForRequestWithPage)
                    }
                })
            }
        }
        
    }
    
    func getMaxPageNumber(pin: Pin, completionHandlerForMaxPageNumber: (success: Bool, maxPageNumber: Int!) -> Void) {
        let parameters = [
            Constants.ParameterKeys.Method: Constants.ParameterValues.SearchMethod,
            Constants.ParameterKeys.APIKey: Constants.ParameterValues.APIKey,
            Constants.ParameterKeys.Latitude: pin.latitude,
            Constants.ParameterKeys.Longitude: pin.longitude,
            Constants.ParameterKeys.Extras: Constants.ParameterValues.MediumURL,
            Constants.ParameterKeys.Format: Constants.ParameterValues.JSONFormat,
            Constants.ParameterKeys.NoJSONCallBack: Constants.ParameterValues.DisableJSONCallback,
        ]
        
        taskForGetMethod(parameters) { (success, data) in
            if success {
                self.getPhotoDictionary(data, completionHandlerForPhotoDictionary: { (success, dictionary) in
                    if success {
                        guard let maxPageNumber = dictionary["pages"] as? Int else {
                            completionHandlerForMaxPageNumber(success: false, maxPageNumber: nil)
                            return
                        }
                        print(maxPageNumber)
                        completionHandlerForMaxPageNumber(success: true, maxPageNumber: maxPageNumber)
                    } else {
                        completionHandlerForMaxPageNumber(success: false, maxPageNumber: nil)
                    }
                })
            } else {
                completionHandlerForMaxPageNumber(success: false, maxPageNumber: nil)
            }
        }
    }
    
    func getPhotoDictionary(results: AnyObject!, completionHandlerForPhotoDictionary: (success: Bool, dictionary: [String:AnyObject]!) -> Void) {
        guard let photos = results["photos"] as? [String:AnyObject] else {
            print("No value for key 'photos'")
            completionHandlerForPhotoDictionary(success: false, dictionary: nil)
            return
        }
        
        completionHandlerForPhotoDictionary(success: true, dictionary: photos)
    }
    
    func parseFlickrImageUrl(results: AnyObject!, completionHandlerForParseImageUrl: (success: Bool, results: [String]!, maxPageNumber: Int!) -> Void) {
        var imageUrl = [String]()
        
        func displayError(error: String) {
            print(error)
            completionHandlerForParseImageUrl(success: false, results: nil, maxPageNumber: nil)
            return
        }
        
        guard let photoArray = results["photo"] as? [[String:AnyObject]] else {
            displayError("No value for key photo")
            return
        }
        
        guard let pageNumber = results["pages"] as? Int else {
            displayError("NO page number")
            return
        }
        
        for photo in photoArray {
            guard let url = photo["url_m"] as? String else {
                displayError("No value for key 'url_m'")
                return
            }
            
            imageUrl.append(url)
        }
        
        completionHandlerForParseImageUrl(success: true, results: imageUrl, maxPageNumber: pageNumber)
    }
    
    func getImageFromURL(photo: Photo, completionHandlerForPhotoData: (data: NSData?) -> Void) {
        let url = photo.imageURL
        let request = NSURLRequest(URL: NSURL(string: url)!)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            guard (error == nil) else {
                print(error?.localizedDescription)
                print("NO PHOTO")
                return
            }
            
            guard let data = data else {
                print("no data")
                return
            }
            
            completionHandlerForPhotoData(data: data)
        }
        
        task.resume()
    }
}











