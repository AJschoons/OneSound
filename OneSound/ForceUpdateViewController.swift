//
//  ForceUpdateViewController.swift
//  OneSound
//
//  Created by adam on 2/17/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

let ForceUpdateViewControllerNibName = "ForceUpdateViewController"

class ForceUpdateViewController: OSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        osvcVariables.screenName = ForceUpdateViewControllerNibName
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
