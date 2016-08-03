//
//  FlickrConvinience.swift
//  Virtual Tourist
//
//  Created by Ramiro H. Lopez on 7/29/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    func startImageUrlRequest(pin: Pin, completionHandlerForUrlRequest: (success: Bool, results: [String]!) -> Void) {
        
        let parameters = [
            Constants.ParameterKeys.Method: Constants.ParameterValues.SearchMethod,
            Constants.ParameterKeys.APIKey: Constants.ParameterValues.APIKey,
            Constants.ParameterKeys.Latitude: pin.latitude,
            Constants.ParameterKeys.Longitude: pin.longitude,
            Constants.ParameterKeys.Extras: Constants.ParameterValues.MediumURL,
            Constants.ParameterKeys.Format: Constants.ParameterValues.JSONFormat,
            Constants.ParameterKeys.NoJSONCallBack: Constants.ParameterValues.DisableJSONCallback
        ]
        
        taskForGetMethod(parameters) { (success, data) in
            if success {
                self.getPhotoDictionary(data, completionHandlerForPhotoDictionary: { (sucess, dictionary) in
                    if success {
                        self.imageURLRequestWithPage(pin, results: dictionary, completionHandlerForPageCheck: completionHandlerForUrlRequest)
                    } else {
                        completionHandlerForUrlRequest(success: false, results: nil)
                    }
                })
            } else {
                completionHandlerForUrlRequest(success: false, results: nil)
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
    
    func imageURLRequestWithPage(pin: Pin, results: AnyObject!, completionHandlerForPageCheck: (success: Bool, results: [String]!) -> Void) {
        var randomPage: Int
        
        func displayError(error: String) {
            print(error)
            completionHandlerForPageCheck(success: false, results: nil)
        }
        
        guard let pageNumber = results["pages"] as? Int else {
            displayError("No value for key 'pages")
            return
        }
        
        if pageNumber > 1 {
            randomPage = Int(arc4random_uniform(UInt32(pageNumber)))
        } else {
            randomPage = pageNumber
        }
        
        let parameters = [
            Constants.ParameterKeys.Method: Constants.ParameterValues.SearchMethod,
            Constants.ParameterKeys.APIKey: Constants.ParameterValues.APIKey,
            Constants.ParameterKeys.Latitude: pin.latitude,
            Constants.ParameterKeys.Longitude: pin.longitude,
            Constants.ParameterKeys.Extras: Constants.ParameterValues.MediumURL,
            Constants.ParameterKeys.Format: Constants.ParameterValues.JSONFormat,
            Constants.ParameterKeys.NoJSONCallBack: Constants.ParameterValues.DisableJSONCallback,
            Constants.ParameterKeys.Page: randomPage
        ]
        
        taskForGetMethod(parameters) { (success, data) in
            if success {
                self.getPhotoDictionary(data, completionHandlerForPhotoDictionary: { (sucess, dictionary) in
                    if sucess {
                        self.parseFlickrImageUrl(dictionary, completionHandlerForParseImageUrl: { (success, results) in
                            if sucess {
                                self.getRandomURLs(results, completionHandlerForRandomURL: completionHandlerForPageCheck)
                            } else {
                                completionHandlerForPageCheck(success: false, results: nil)
                            }
                        })
                    } else {
                        completionHandlerForPageCheck(success: false, results: nil)
                    }
                })
            } else {
                completionHandlerForPageCheck(success: false, results: nil)
            }
        }
    }
    
    func parseFlickrImageUrl(results: AnyObject!, completionHandlerForParseImageUrl: (success: Bool, results: [String]!) -> Void) {
        var imageUrl = [String]()
        
        func displayError(error: String) {
            print(error)
            completionHandlerForParseImageUrl(success: false, results: nil)
            return
        }
        
        guard let photoArray = results["photo"] as? [[String:AnyObject]] else {
            displayError("No value for key photo")
            return
        }
        
        for photo in photoArray {
            guard let url = photo["url_m"] as? String else {
                displayError("No value for key 'url_m'")
                return
            }
            
            imageUrl.append(url)
        }
        
        completionHandlerForParseImageUrl(success: true, results: imageUrl)
    }
    
    func getRandomURLs(urlArray: [String], completionHandlerForRandomURL: (sucess: Bool, results: [String]!) ->Void) {
        var randomIndex: Int
        var results = [String]()
        if urlArray.count > 0 {
            if urlArray.count > 21 {
                for _ in 1...21 {
                    randomIndex = Int(arc4random_uniform(UInt32(urlArray.count)))
                    results.append(urlArray[randomIndex])
                }
            } else {
                results = urlArray
            }
            completionHandlerForRandomURL(sucess: true, results: results)
        } else {
            completionHandlerForRandomURL(sucess: false, results: nil)
        }
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











