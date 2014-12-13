//
//  SearchViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let SearchViewControllerNibName = "SearchViewController"

class SearchViewController: UIViewController {
    
    var createPartyButton: UIBarButtonItem!
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    @IBOutlet weak var partySearchTextField: UITextField!
    @IBOutlet weak var searchResultsTable: UITableView!
    @IBOutlet weak var animatedOneSoundOne: UIImageView!
    
    func createParty() {
        if LocalUser.sharedUser.guest == false {
            let createPartyStoryboard = UIStoryboard(name: "CreateParty", bundle: nil)
            let createPartyViewController = createPartyStoryboard.instantiateViewControllerWithIdentifier("CreatePartyViewController") as CreatePartyViewController
            createPartyViewController.partyAlreadyExists = false
            // TODO: create the delegate methods and see what they mean
            //createPartyViewController.delegate = self
            let navC = UINavigationController(rootViewController: createPartyViewController)
            
            let delegate = UIApplication.sharedApplication().delegate as AppDelegate
            let fvc = delegate.revealViewController!.frontViewController
            fvc.presentViewController(navC, animated: true, completion: nil)
        } else {
            let alert = UIAlertView(title: "Guests cannot create parties", message: "Please become a full account by logging in with Facebook, then try again", delegate: nil, cancelButtonTitle: "Ok")
            alert.show()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Search"
        
        // Setup the revealViewController to work for this view controller,
        // add its sideMenu icon to the nav bar
        let revealController = revealViewController()
        revealController.panGestureRecognizer()
        revealController.tapGestureRecognizer()
        let revealButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: revealController, action: "revealToggle:")
        navigationItem.leftBarButtonItem = revealButtonItem
        
        createPartyButton = UIBarButtonItem(title: "Create", style: UIBarButtonItemStyle.Plain, target: self, action: "createParty")
        navigationItem.rightBarButtonItem = createPartyButton
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    // Copy pasta'd from Profile view controller to have the same kind of refresh logic
    // Keeping the commented out things for now to show what kind of changes were made for that
    // TODO: update the refresh to remove comments irrelevant to this controller when finished w/ it
    func refresh() {
        println("refreshing PartyMembersViewController")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                hideMessages()
                if LocalUser.sharedUser.guest == true {
                    createPartyButton.enabled = false
                } else {
                    createPartyButton.enabled = true
                }
            } else {
                //setUserInfoHidden(true)
                //setStoriesTableToHidden(true)
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart One Sound")
                disableButtons()
            }
        } else {
            //setUserInfoHidden(true)
            //setStoriesTableToHidden(true)
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use One Sound")
            disableButtons()
        }
    }
    
    func showMessages(mainLine: String?, detailLine: String?) {
        if mainLine != nil {
            messageLabel1!.alpha = 1
            messageLabel1!.text = mainLine
        }
        if detailLine != nil {
            messageLabel2!.alpha = 1
            messageLabel2!.text = detailLine
        }
    }
    
    func disableButtons() {
        createPartyButton.enabled = false
    }
    
    func hideMessages() {
        messageLabel1!.alpha = 0
        messageLabel1!.text = ""
        messageLabel2!.alpha = 0
        messageLabel2!.text = ""
    }
}
