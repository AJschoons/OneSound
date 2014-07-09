//
//  SideNavigationViewController.swift
//  OneSound
//
//  Created by adam on 7/9/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SideNavigationViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.frame = CGRectMake(0, 0, view.frame.width, view.frame.height + 20.0)
        view.bounds = CGRectMake(0, 0, view.frame.width, view.frame.height + 20.0)
    }
}