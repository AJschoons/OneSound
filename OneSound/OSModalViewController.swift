//
//  OSModalViewController.swift
//  OneSound
//
//  Created by adam on 1/5/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

// Only use when the VC will be presented modally
// This is because this class customizes the navigationItem, creating a unique UINavigationItem instance, which isn't needed if the VC isn't being presented in a navigation controller
class OSModalViewController: OSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "navigationBarBackground"), forBarMetrics: UIBarMetrics.Default)
        navigationController?.navigationBar.shadowImage = UIImage(named: "navigationBarShadow")
        navigationController?.navigationBar.tintColor = UIColor.blue()
        navigationController?.navigationBar.barTintColor = UIColor.white()
        navigationController?.navigationBar.translucent = true
        navigationController?.navigationBar
    }
}
