//
//  PartySongsViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class PartySongsViewController: UIViewController {
    @IBOutlet var messageLabel1: UILabel
    @IBOutlet var messageLabel2: UILabel

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController.visibleViewController.title = "Songs"
    }
}
