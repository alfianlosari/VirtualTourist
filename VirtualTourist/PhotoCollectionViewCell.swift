//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Alfian Losari on 28/08/17.
//  Copyright © 2017 Alfian Losari. All rights reserved.
//

import UIKit
import CoreData

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    

    override func layoutSubviews() {
        super.layoutSubviews()
//        
//        self.backgroundView = UIView(frame: self.bounds)
//        self.backgroundView?.backgroundColor = .lightGray
//            
//        self.selectedBackgroundView = UIView(frame: self.bounds)
//        self.selectedBackgroundView?.backgroundColor = .red
    }
    
    func setup(photo: Photo) {
        if let imageData = photo.imageData as Data?,
            let image = UIImage(data: imageData) {
            activityIndicator.stopAnimating()
            imageView.isHidden = false
            imageView.image = image
            
        } else {
            activityIndicator.startAnimating()
            imageView.isHidden = true
            imageView.image = nil
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.imageView.alpha = 0.3
            } else {
                self.imageView.alpha = 1.0
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    
        
    }
    
}
