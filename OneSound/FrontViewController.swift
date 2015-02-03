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
        PartyManager.sharedParty.getMusicStreamControl(respondToChangeAttempt: { success in
            if success {
                let alert = UIAlertView(title: "Got Music Control!", message: "Woo hoo!", delegate: self, cancelButtonTitle: "Okay")
                alert.show()
            } else {
                let alert = UIAlertView(title: "Music Control Failure", message: "Failed to get the music stream control. Please reload the party settings and try again", delegate: self, cancelButtonTitle: "Okay")
                alert.show()
            }
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Front View"
        
        let fnc = getFrontNavigationController()
        let sideMenuButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: fnc, action: "toggleSideMenu")
        navigationItem.leftBarButtonItem = sideMenuButtonItem
    }
}

