//
//  ProfileViewController.swift
//  OneSound
//
//  Created by adam on 7/21/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var signOutButton: UIBarButtonItem?
    @IBOutlet weak var settingsButton: UIBarButtonItem?
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    @IBOutlet weak var facebookSignInButton: UIButton?
    
    var user: LocalUser?

    @IBAction func signIntoFacebook(sender: AnyObject) {
        let fbSession = FBSession.activeSession()
        // Only sign in if not already signed in
        if (fbSession.state != FBSessionStateOpen) && (fbSession.state != FBSessionStateOpenTokenExtended) {
            FBSession.openActiveSessionWithReadPermissions(facebookSessionPermissions, allowLoginUI: true, completionHandler: { session, state, error in
                let delegate = UIApplication.sharedApplication().delegate as AppDelegate
                // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
                delegate.sessionStateChanged(session, state: state, error: error)
                }
            )
        }
    }
    
    @IBAction func signOut(sender: AnyObject) {
        // Only proceeds if refresh leaves view controller with a valid user
        if refresh() {
            if user!.guest {
                // Let the guest know that signing out a guest account doesn't really do anything
                let alert = UIAlertView(title: "Signing Out Guest", message: "Signing out of guest account deletes current guest account and signs into a new guest account. To sign into a full account, login with Facebook, and your guest account is automatically signed out.", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Ok")
                alert.tag = 101
                alert.show()
            } else {
                // TODO: If full user sign out
            }
        }
    }
    
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
        
        disableButtons()
        hideMessages()
        
        // Can also add email and user_friends
        facebookSignInButton!.backgroundColor = UIColor.blue()
        facebookSignInButton!.layer.cornerRadius = 3.0
        //facebookLoginButton.readPermissions = ["public_profile"]
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: FacebookSessionChangeNotification, object: nil)
        
        // Temporary testing code
        //LocalUser.sharedUser.signIntoGuestAccount(118, apiToken: "BuQtw6ER8rZqmrdDmRLZpL5fgZbzwd9SQnI7LJb2")
    }
    
    override func viewWillAppear(animated: Bool) {
        refresh()
    }
    
    override func viewWillDisappear(animated: Bool) {
        disableButtons()
        hideMessages()
    }
    
    func refresh() -> Bool {
        // Returns true if refreshed with a valid user variable for controller
        var validUser = false
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            let localUser = LocalUser.sharedUser
            if localUser.setup {
                user = localUser
                user!.updateLocalUserInformationFromServer()
                validUser = true
                
                if user!.guest {
                    showMessages("Guests can only join and use parties", message2: "Please sign in with Facebook to use social features")
                    facebookSignInButton!.hidden = false
                    signOutButton!.enabled = true
                } else {
                    // Full accounts
                    facebookSignInButton!.hidden = true
                    hideMessages()
                }
            } else {
                showMessages("Not signed into an account", message2: "Please connect to the internet and try again")
                disableButtons()
            }
        } else {
            showMessages("Not connected to the internet", message2: "Please connect to the internet and try again")
            disableButtons()
        }
        
        return validUser
    }
    
    func showMessages(message1: String?, message2: String?) {
        if message1 {
            messageLabel1!.alpha = 1
            messageLabel1!.text = message1
        }
        if message2 {
            messageLabel2!.alpha = 1
            messageLabel2!.text = message2
        }
    }
    
    func hideMessages() {
        messageLabel1!.alpha = 0
        messageLabel1!.text = ""
        messageLabel2!.alpha = 0
        messageLabel2!.text = ""
    }
    
    func disableButtons() {
        signOutButton!.enabled = false
        settingsButton!.enabled = false
        facebookSignInButton!.hidden = true
    }
}

extension ProfileViewController: UIAlertViewDelegate {
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == 101 {
            // If guest is trying to log out
            if buttonIndex == 1 {
                // If guest wants to sign out, delete all info and get new guest account, then refresh
                LocalUser.sharedUser.deleteAllSavedUserInformation()
                LocalUser.sharedUser.setupGuestAccount()
                refresh()
            }
        }
    }
}
