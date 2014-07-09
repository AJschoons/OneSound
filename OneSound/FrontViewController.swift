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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        overlay.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        overlay.backgroundColor = UIColor.blackColor()
        overlay.alpha = 0.0
        view.addSubview(overlay)
        
        title = "Front View"
        
        let revealController = revealViewController()
        revealController.panGestureRecognizer()
        revealController.tapGestureRecognizer()
        let revealButtonItem = UIBarButtonItem(image: UIImage(named: "List.png"), style: UIBarButtonItemStyle.Plain, target: revealController, action: "revealToggle:")
        navigationItem.leftBarButtonItem = revealButtonItem
        
        navigationController.navigationBar.barTintColor = UIColor.whiteColor()
        navigationController.navigationBar.translucent = false
    }

}
