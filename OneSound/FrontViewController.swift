//
//  FrontViewController.swift
//  OneSound
//
//  Created by adam on 7/8/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class FrontViewController: UIViewController {
    
    let overlay = UIView()
    var pL = true
    
    @IBAction func modal(sender: AnyObject) {
        presentViewController(TestViewController(), animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Front View"
        
        let revealController = revealViewController()
        revealController.panGestureRecognizer()
        revealController.tapGestureRecognizer()
        let revealButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: revealController, action: "revealToggle:")
        navigationItem.leftBarButtonItem = revealButtonItem
    }
}

