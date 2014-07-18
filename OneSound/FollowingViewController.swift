//
//  FollowingViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class FollowingViewController: UIViewController {
    @IBOutlet var messageLabel1: UILabel
    @IBOutlet var messageLabel2: UILabel

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Following"
        
        // Setup the revealViewController to work for this view controller,
        // add its sideMenu icon to the nav bar
        let revealController = revealViewController()
        revealController.panGestureRecognizer()
        revealController.tapGestureRecognizer()
        let revealButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: revealController, action: "revealToggle:")
        navigationItem.leftBarButtonItem = revealButtonItem
    }
}
