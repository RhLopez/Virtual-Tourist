//
//  Constants.swift
//  Virtual Tourist
//
//  Created by Ramiro H. Lopez on 7/29/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    struct Constants {
        
        struct API {
            static let APIScheme = "https"
            static let APIHost = "api.flickr.com"
            static let APIPath = "/services/rest"
        }
        
        struct ParameterKeys {
            static let Method = "method"
            static let APIKey = "api_key"
            static let Latitude = "lat"
            static let Longitude = "lon"
            static let Radius = "radius"
            static let Format = "format"
            static let NoJSONCallBack = "nojsoncallback"
            static let Extras = "extras"
            static let PerPage = "per_page"
            static let Page = "page"
        }
        
        struct ParameterValues {
            static let APIKey = "28af64af1df718d65df6e2e7b26414cb"
            static let APISectret = "4e4306259905e854"
            static let SearchMethod = "flickr.photos.search"
            static let RadiusAmount = "3"
            static let JSONFormat = "json"
            static let DisableJSONCallback = "1"
            static let MediumURL = "url_m"
            static let PerPageLimit = 21
        }
    }
}