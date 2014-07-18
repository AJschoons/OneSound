//
//  ProfileViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet var signOutButton: UIBarButtonItem
    @IBOutlet var settingsButton: UIBarButtonItem
    @IBOutlet var messageLabel1: UILabel
    @IBOutlet var messageLabel2: UILabel

    var user: LocalUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Profile"
        
        // Setup the revealViewController to work for this view controller,
        // add its sideMenu icon to the nav bar
        let revealController = revealViewController()
        revealController.panGestureRecognizer()
        revealController.tapGestureRecognizer()
        let revealButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: revealController, action: "revealToggle:")
        navigationItem.leftBarButtonItem = revealButtonItem
        
        disableToolbarButtons()
        hideMessages()
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        refresh()
    }
    
    override func viewWillDisappear(animated: Bool) {
        disableToolbarButtons()
        hideMessages()
    }
    
    func refresh() {
        if AFNetworkReachabilityManager.sharedManager().reachable {
            let localUser = LocalUser.sharedUser
            if localUser.setup {
                user = localUser
                user!.updateLocalUserInformationFromServer()
                
                if user!.guest {
                    showMessages("Guests can only join and use parties", message2: "Please sign in with Facebook to use social features")
                }
            } else {
                showMessages("Not signed into an account", message2: "Please connect to the internet and try again")
            }
        } else {
            showMessages("Not connected to the internet", message2: "Please connect to the internet and try again")
        }
    }
    
    func showMessages(message1: String?, message2: String?) {
        if message1 {
            messageLabel1.alpha = 1
            messageLabel1.text = message1
        }
        if message2 {
            messageLabel2.alpha = 1
            messageLabel2.text = message2
        }
    }
    
    func hideMessages() {
        messageLabel1.alpha = 0
        messageLabel1.text = ""
        messageLabel2.alpha = 0
        messageLabel2.text = ""
    }
    
    func enableToolbarButtons() {
        signOutButton.enabled = true
        settingsButton.enabled = true
    }
    
    func disableToolbarButtons() {
        signOutButton.enabled = false
        settingsButton.enabled = false
    }
}
