//
//  LocationCellFooterViewController.swift
//  OneSound
//
//  Created by adam on 5/24/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

let LocationCellFooterViewControllerNibName = "LocationCellFooterViewController"

protocol LocationCellFooterDelegate {
    func receivedLocation(location: CLLocation)
}

class LocationCellFooterViewController: UIViewController {

    @IBOutlet weak var detailMessageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    var delegate: LocationCellFooterDelegate?
    
    @IBAction func onRetryButton(sender: AnyObject) {
        retryButton.hidden = true
        hideDetailMessage()
        getLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup retry button
        retryButton.layer.borderWidth = 1
        retryButton.layer.borderColor = UIColor.grayDark().CGColor
        retryButton.layer.cornerRadius = 5
        retryButton.layer.masksToBounds = true
        
        getLocation()
    }
    
    func getLocation() {
        showActivityIndicator()
        
        LocationManager.sharedManager.getLocationForInitialPartyCreation(
            success: {[weak self] location, accuracy in
                self?.hideActivityIndicator()
                self?.delegate?.receivedLocation(location)
            },
            failure: {[weak self] errorDescription in
                dispatchAsyncToMainQueue(action: {
                    self?.hideActivityIndicator()
                    self?.retryButton.hidden = false
                    self?.showDetailMessage(errorDescription)
                })
            }
        )
    }
    
    func showDetailMessage(detailMessage: String) {
        detailMessageLabel.hidden = false
        detailMessageLabel.text = detailMessage
    }
    
    func hideDetailMessage() {
        detailMessageLabel.hidden = true
    }
    
    func showActivityIndicator() {
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        activityIndicatorLabel.hidden = false
    }
    
    func hideActivityIndicator() {
        activityIndicator.hidden = true
        activityIndicator.stopAnimating()
        activityIndicatorLabel.hidden = true
    }
}
