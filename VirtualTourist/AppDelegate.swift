//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Alfian Losari on 26/08/17.
//  Copyright © 2017 Alfian Losari. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? 
    
    lazy var persistentContainer: NSPersistentContainer = {
        let persistentContainer = NSPersistentContainer(name: "VirtualTourist")
        persistentContainer.loadPersistentStores(completionHandler: { (description, error) in
            if let error = error {
                fatalError("Unresolved Error. \(error.localizedDescription)")
            }
        })
        return persistentContainer
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        guard let navigationVC = window?.rootViewController as? UINavigationController,
            let mapVC = navigationVC.viewControllers.first as? MapViewController else {
                fatalError("Invalid View Controller")
        }
        let managedObjectContext = persistentContainer.viewContext
        mapVC.managedObjectContext = managedObjectContext
        return true
    }

}

