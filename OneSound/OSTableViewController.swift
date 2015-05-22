//
//  OSTableViewController.swift
//  OneSound
//
//  Created by adam on 5/21/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

class OSTableViewController: UITableViewController {
    
    // The variables needed for all OSViewControllers, OSTableViewControllers, etc
    var osvcVariables = OSViewControllerVariables()

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        setGoogleAnalyticsTrackerWithScreenNameFromOSVCvariables()
    }

    func setGoogleAnalyticsTrackerWithScreenNameFromOSVCvariables() {
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: osvcVariables.screenName)
            tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject])
        }
    }
}

extension OSTableViewController: OSViewControllerMethods {
    func updateUI() {
        
    }
    
    func refresh() {
        
    }
}