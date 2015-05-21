//
//  OSViewController.swift
//  OneSound
//
//  Created by adam on 1/5/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

class OSViewController: UIViewController {

    // The variables needed for all OSViewControllers, OSTableViewControllers, etc
    var osvcVariables = OSViewControllerVariables()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "navigationBarBackground"), forBarMetrics: UIBarMetrics.Default)
        navigationController?.navigationBar.shadowImage = UIImage(named: "navigationBarShadow")
        navigationController?.navigationBar.tintColor = UIColor.blue()
        navigationController?.navigationBar.barTintColor = UIColor.white()
        navigationController?.navigationBar.translucent = true
        navigationController?.navigationBar
        */
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
