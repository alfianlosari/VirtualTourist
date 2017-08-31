//
//  Pin+Extension.swift
//  VirtualTourist
//
//  Created by Alfian Losari on 28/08/17.
//  Copyright © 2017 Alfian Losari. All rights reserved.
//

import Foundation
import MapKit
import CoreData

extension Pin {
    
    var toMKPointAnnotation: MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        return annotation
    }
    
    static func insertPin(coordinate: CLLocationCoordinate2D, moc: NSManagedObjectContext) -> Pin {
        let pin = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: moc) as! Pin
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.createdAt = Date() as NSDate
        return pin
    }
    
    
    static func getPin(coordinate: CLLocationCoordinate2D, moc: NSManagedObjectContext) -> Pin? {
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        
        fetchRequest.predicate = NSPredicate(format: "%K = %@ AND %K = %@", #keyPath(Pin.latitude), NSNumber(value: coordinate.latitude), #keyPath(Pin.longitude), NSNumber(value: coordinate.longitude))
        fetchRequest.fetchLimit = 1
        
        let pins = try! moc.fetch(fetchRequest)
        return pins.first
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    
    
}
