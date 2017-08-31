//
//  FlickrPhoto.swift
//  VirtualTourist
//
//  Created by Alfian Losari on 29/08/17.
//  Copyright © 2017 Alfian Losari. All rights reserved.
//

import Foundation



struct FlickrPhoto {
    var id: String
    var url: String
    
    static func constructFlickrPhotoURLString(photoId: String, farmdId: String, serverId: String, secret: String) -> String {
        return "https://farm1.staticflickr.com/\(serverId)/\(photoId)_\(secret)_m.jpg"
    }
}

extension FlickrPhoto {
    
    init?(json: [String: Any]) {
        guard
            let photoId = json["id"] as? String,
            let farmId = json["farm"] as? Int,
            let serverId = json["server"] as? String,
            let secretId = json["secret"] as? String
        else { return nil }
        self.id = photoId
        self.url = FlickrPhoto.constructFlickrPhotoURLString(photoId: photoId, farmdId: "\(farmId)", serverId: serverId, secret: secretId)
        
    }
    
    
}
