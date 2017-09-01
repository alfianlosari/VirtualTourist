//
//  PinDetailViewController.swift
//  VirtualTourist
//
//  Created by Alfian Losari on 26/08/17.
//  Copyright © 2017 Alfian Losari. All rights reserved.
//

import UIKit
import MapKit
import CoreData

private let reuseIdentifier = "Cell"

class PinDetailViewController: UIViewController {
    
    @IBOutlet weak var collectionFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var bottomBarItem: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionBarItem: UIBarButtonItem!
    var blockOperations: [BlockOperation] = []

    var pin: Pin!

    lazy var fetchedResultController: NSFetchedResultsController<Photo> = {
        let fr = NSFetchRequest<Photo>(entityName: "Photo")
        fr.predicate = NSPredicate(format: "%K = %@", #keyPath(Photo.pin), self.pin!)
        fr.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Photo.createdAt), ascending: true)
        ]
        let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: self.pin!.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
    }()
    
    
    func setupCollectionViewLayout(size: CGSize) {
        let space: CGFloat = 3.0
        let dimension: CGFloat
        
        if size.width < size.height {
            dimension = (size.width - (2 * space)) / 3.0
        } else {
            dimension = (size.width - (5 * space)) / 6.0
        }
        
        collectionFlowLayout?.minimumInteritemSpacing = space
        collectionFlowLayout?.minimumLineSpacing = space
        collectionFlowLayout?.itemSize = CGSize(width: dimension, height: dimension)
        
    }
    
    func updateBottomBarItem() {
        let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems ?? []
        if selectedIndexPaths.isEmpty {
            self.bottomBarItem.title = "New Collection"
        } else {
            self.bottomBarItem.title = "Remove Selected Pictures"
        }
    }
    
    var randomPage: Int {
        return Int(arc4random_uniform(100) + 1)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        self.collectionView.allowsMultipleSelection = true
        setupCollectionViewLayout(size: view.frame.size)

        let pins = self.fetchedResultController.fetchedObjects ?? []
        if pins.isEmpty {
            getPhotosFromFlickr()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setupCollectionViewLayout(size: size)
    }
    
    func setupMapView() {
        let annotation = pin.toMKPointAnnotation
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 500, 500)
        let adjustedRegion = mapView.regionThatFits(region)
        mapView.setRegion(adjustedRegion, animated: true)
        mapView.isUserInteractionEnabled = false
    }
    
    func getPhotosFromFlickr() {
        self.bottomBarItem.isEnabled = false
        guard let moc = self.pin.managedObjectContext else { return }
        let photos = self.pin.photos?.allObjects as? [Photo] ?? []
        photos.forEach { moc.delete($0) }
        
        do {
            try moc.save()
            FlickrPhotoStore.searchPhotos(lat: pin.latitude, lon: pin.longitude, page: randomPage) { [weak self] (photos, error) in
                self?.bottomBarItem.isEnabled = true
                guard let strongSelf = self,
                    let pin = strongSelf.pin,
                    let moc = pin.managedObjectContext
                else { return }
                
                if let error = error {
                    strongSelf.showAlert(title: nil, message: error.localizedDescription)
                    return
                }
                
                guard let photos = photos else { return }
                photos.forEach { _ = Photo.insertPhoto(pin: pin, url: $0.url, moc: moc) }
                
                do {
                    try moc.save()
                } catch {
                    self?.showAlert(title: nil, message: error.localizedDescription)
                    
                }
            }
        } catch  {
            self.showAlert(title: nil, message: error.localizedDescription)
        }
        
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    
    @IBAction func bottomBarTapped(_ sender: Any) {
        let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems ?? []
        if selectedIndexPaths.isEmpty {
            self.getPhotosFromFlickr()
        } else {
            guard let moc = self.pin.managedObjectContext else { return }
            selectedIndexPaths.forEach({ (indexPath) in
                let photo = self.fetchedResultController.object(at: indexPath)
                moc.delete(photo)
            })
            
            do {
                try moc.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }


    deinit {
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }
        blockOperations.removeAll(keepingCapacity: false)
    }


}


extension PinDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        let photo = self.fetchedResultController.object(at: indexPath)
        cell.setup(photo: photo)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = self.fetchedResultController.object(at: indexPath)
        guard let photoURL = photo.url, photo.imageData == nil else { return }
        FlickrPhotoStore.getPhoto(urlText: photoURL) {[weak self] (data, error) in
            guard
                let strongSelf = self,
                let pin = strongSelf.pin,
                let data = data,
                let moc = pin.managedObjectContext,
                !pin.isDeleted,
                !photo.isDeleted,
                photo.imageData == nil
            else { return }
            photo.imageData = NSData(data: data)
            do {
                try moc.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let photo = self.fetchedResultController.object(at: indexPath)
        if photo.imageData == nil {
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.updateBottomBarItem()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.updateBottomBarItem()
    }
    
}



extension PinDetailViewController: NSFetchedResultsControllerDelegate {
    

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == .insert {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        }
        else if type == .update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
        }
        else if type == .move {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        }
        else if type == .delete {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
        }
    }
    
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        
        if type == .insert {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
        else if type == .update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
        else if type == .delete {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: BlockOperation in self.blockOperations {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
            self.updateBottomBarItem()
        })
    }
    
}
