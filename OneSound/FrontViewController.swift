//
//  FrontViewController.swift
//  OneSound
//
//  Created by adam on 7/8/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let FrontViewControllerNibName = "FrontViewController"

class FrontViewController: UIViewController {
    
    var pL = true
    
    @IBAction func resetImageCache(sender: AnyObject) {
        SDWebImageManager.sharedManager().imageCache.clearMemory()
        SDWebImageManager.sharedManager().imageCache.clearDisk()
    }
    
    @IBAction func resetUserInfo(sender: AnyObject) {
        println("deleted all user info")
        let user = UserManager.sharedUser
        user.deleteAllSavedUserInformation()
    }
    
    @IBAction func modal(sender: AnyObject) {
        presentViewController(LoggingInSpashViewController(nibName: LoggingInSpashViewControllerNibName, bundle: nil), animated: true, completion: nil)
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

