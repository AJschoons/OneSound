//
//  HistoryViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "History"
        
        // Setup the revealViewController to work for this view controller,
        // add its sideMenu icon to the nav bar
        let revealController = revealViewController()
        revealController.panGestureRecognizer()
        revealController.tapGestureRecognizer()
        let revealButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: revealController, action: "revealToggle:")
        navigationItem.leftBarButtonItem = revealButtonItem
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        
        hideMessages()
    }
    
    override func viewWillAppear(animated: Bool) {
        refresh()
    }
    
    // Copy pasta'd from Profile view controller to have the same kind of refresh logic
    // Keeping the commented out things for now to show what kind of changes were made for that
    // TODO: update the refresh to remove comments irrelevant to this controller when finished w/ it
    func refresh() -> Bool {
        // Returns true if refreshed with a valid user
        var validUser = false
        println("refreshing HistoryViewController")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            let localUser = LocalUser.sharedUser
            if LocalUser.sharedUser.setup == true {
                validUser = true
                LocalUser.sharedUser.updateLocalUserInformationFromServer(
                    addToSuccess: {
                        if LocalUser.sharedUser.guest == true {
                            //self.setUserInfoHidden(true)
                            //self.setStoriesTableToHidden(true)
                            self.hideMessages()
                            //self.facebookSignInButton!.hidden = false
                            //self.signOutButton!.enabled = false
                            //self.settingsButton!.enabled = false
                        } else {
                            // Full accounts
                            //self.facebookSignInButton!.hidden = true
                            //self.signOutButton!.enabled = true
                            //self.settingsButton!.enabled = true
                            //self.setStoriesTableToHidden(false)
                            self.hideMessages()
                            //self.setUserInfoHidden(false)
                        }
                    }
                )
            } else {
                //setUserInfoHidden(true)
                //setStoriesTableToHidden(true)
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart One Sound")
                //disableButtons()
            }
        } else {
            //setUserInfoHidden(true)
            //setStoriesTableToHidden(true)
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use One Sound")
            //disableButtons()
        }
        
        return validUser
    }
    
    func showMessages(mainLine: String?, detailLine: String?) {
        if mainLine {
            messageLabel1!.alpha = 1
            messageLabel1!.text = mainLine
        }
        if detailLine {
            messageLabel2!.alpha = 1
            messageLabel2!.text = detailLine
        }
    }
    
    func hideMessages() {
        messageLabel1!.alpha = 0
        messageLabel1!.text = ""
        messageLabel2!.alpha = 0
        messageLabel2!.text = ""
    }
}
