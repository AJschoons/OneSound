//
//  LoginColorViewController.swift
//  OneSound
//
//  Created by adam on 7/16/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class LoginColorViewController: UITableViewController {
    
    let colorNames = ["Random", "Green", "Turquiose"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Choose Color"
    }

}
