//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Ramiro H. Lopez on 7/29/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class FlickrClient {
    
    static let sharedInstance = FlickrClient()
    
    let session = NSURLSession.sharedSession()
    
    func taskForGetMethod(parameters: [String:AnyObject], completionHandlerForGetMethod: (success: Bool, data: AnyObject!) -> Void) {
        let request = NSURLRequest(URL: flickURL(parameters))
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            guard (error == nil) else {
                print(error?.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                print("Status Code")
                return
            }
            
            guard let data = data else {
                print("Data problem")
                return
            }
            self.seriliazeData(data, completionHandlerForSerialization: completionHandlerForGetMethod)
        }
        
        task.resume()
    }
    
    private func seriliazeData(data: NSData, completionHandlerForSerialization: (success: Bool, data: AnyObject!) -> Void) {
        var serializedData: AnyObject!
        
        do {
            serializedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            completionHandlerForSerialization(success: false, data: nil)
        }
        
        completionHandlerForSerialization(success: true, data: serializedData)
    }
    
    private func flickURL(parameters: [String:AnyObject]) -> NSURL{
        let compoments = NSURLComponents()
        compoments.scheme = Constants.API.APIScheme
        compoments.host = Constants.API.APIHost
        compoments.path = Constants.API.APIPath
        compoments.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            compoments.queryItems!.append(queryItem)
        }
        
        return compoments.URL!
    }
}
