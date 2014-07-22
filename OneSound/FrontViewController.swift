//
//  FrontViewController.swift
//  OneSound
//
//  Created by adam on 7/8/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class FrontViewController: UIViewController {
    
    var pL = true
    @IBAction func resetUserInfo(sender: AnyObject) {
        println("deleted all user info")
        let user = LocalUser.sharedUser
        user.deleteAllSavedUserInformation()
    }
    
    @IBAction func tryLoggingIntoFacebook(sender: AnyObject) {
        /*
        let fbSession = FBSession.activeSession()
        // Only sign in if not already signed in
        if (fbSession.state != FBSessionStateOpen) && (fbSession.state != FBSessionStateOpenTokenExtended) {
            FBSession.openActiveSessionWithReadPermissions(["public_profile", "email"], allowLoginUI: true, completionHandler: { session, state, error in
                let delegate = UIApplication.sharedApplication().delegate as AppDelegate
                // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
                delegate.sessionStateChanged(session, state: state, error: error)
                }
            )
        }
        */
    }
    @IBAction func modal(sender: AnyObject) {
        let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = loginStoryboard.instantiateViewControllerWithIdentifier("LoginViewController") as LoginViewController
        let navC = UINavigationController(rootViewController: loginViewController)
        
        presentViewController(navC, animated: true, completion: nil)
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
        
        /*
        for i in 1...4 {
            OSAPI.sharedClient.GETUser(i,
                success: { data, responseObject in
                    let responseJSON = JSONValue(responseObject)
                    println(responseJSON)
                    let user = User(json: responseJSON)
                    println(user.description())
                },
                failure: defaultAFHTTPFailureBlock
            )
        }
    
        for i in 1...4 {
            OSAPI.sharedClient.GETUserFollowing(i,
                success: { data, responseObject in
                    let responseJSON = JSONValue(responseObject)
                    println(responseJSON)
                },
                failure: defaultAFHTTPFailureBlock
            )
        }
        
        for i in 1...4 {
            OSAPI.sharedClient.GETUserFollowers(i,
                success: { data, responseObject in
                    let responseJSON = JSONValue(responseObject)
                    println(responseJSON)
                },
                failure: defaultAFHTTPFailureBlock
            )
        }
        */
    }
}

