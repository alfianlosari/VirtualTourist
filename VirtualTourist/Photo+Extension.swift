//
//  Photo+Extension.swift
//  VirtualTourist
//
//  Created by Alfian Losari on 29/08/17.
//  Copyright © 2017 Alfian Losari. All rights reserved.
//

import CoreData

extension Photo {
    
    static func insertPhoto(pin: Pin, url: String, moc: NSManagedObjectContext) -> Photo {
        let photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: moc) as! Photo
        photo.createdAt = NSDate()
        photo.url = url
        photo.pin = pin
        return photo
    }
    
    
}
