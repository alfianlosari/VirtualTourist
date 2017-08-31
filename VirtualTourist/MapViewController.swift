//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Alfian Losari on 26/08/17.
//  Copyright © 2017 Alfian Losari. All rights reserved.
//

import UIKit
import MapKit
import CoreData

private let reuseIdentifier = "Pin"
private let pinDetailSegueIdentifier = "DetailPin"

class MapViewController: UIViewController {

    @IBOutlet weak var deleteInfoView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    var managedObjectContext: NSManagedObjectContext!
    
    lazy var fetchedResultsController: NSFetchedResultsController<Pin> = {
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Pin.createdAt), ascending: true)
        ]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupEditBarItem()
        setupLongPressGestureRecognizer()
        loadAnnotations()
    }
    
    func loadAnnotations() {
        self.mapView.removeAnnotations(self.mapView.annotations)
        let pins = self.fetchedResultsController.fetchedObjects ?? []
        let annotations = pins.map { $0.toMKPointAnnotation }
        mapView.addAnnotations(annotations)
    }
    
    func setupLongPressGestureRecognizer() {
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        mapView.addGestureRecognizer(longPressGR)
    }
    
    func longPress(_ sender: UIGestureRecognizer) {
        guard sender.state == .began && !isEditing else { return }
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        guard Pin.getPin(coordinate: coordinate, moc: managedObjectContext) == nil else {
            self.showAlert(title: nil, message: "Pin already exists in selected coordinate")
            return
        }
        
        _ = Pin.insertPin(coordinate: coordinate, moc: managedObjectContext)
    
        do {
            try managedObjectContext.save()
        } catch let error  {
            print(error.localizedDescription)
        }
    }
    
    func setupEditBarItem() {
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        UIView.animate(withDuration: 0.3) { 
            self.deleteInfoView.isHidden = editing ? false : true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == pinDetailSegueIdentifier {
            guard let pinDetailVC = segue.destination as? PinDetailViewController,
                let pin = sender as? Pin
                else { fatalError("Invalid View Controller") }
            pinDetailVC.pin = pin
        }
    }

}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        pinView.animatesDrop = true
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)

        guard
            let coordinate = view.annotation?.coordinate,
            let pin = Pin.getPin(coordinate: coordinate, moc: managedObjectContext)
            else { return }
        
        if isEditing {
            managedObjectContext.delete(pin)
            do {
                try managedObjectContext.save()
            } catch let error  {
                print(error.localizedDescription)
            }
            
            
        } else {
            performSegue(withIdentifier: pinDetailSegueIdentifier, sender: pin)
        }
    }
}

extension MapViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else { return }
        switch type {
        case .insert:
            let annotation = pin.toMKPointAnnotation
            mapView.addAnnotation(annotation)
            
        case .delete:
            self.loadAnnotations()
            
        case .move, .update:
            self.loadAnnotations()
            
        }
    }
    
}



