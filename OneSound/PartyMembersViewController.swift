//
//  PartyMembersViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let PartyMembersViewControllerNibName = "PartyMembersViewController"
let PartyMemberCellIdentifier = "PartyMemberCell"

class PartyMembersViewController: UIViewController {
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    
    @IBOutlet weak var membersTable: UITableView!
    
    override func viewDidLoad() {
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        
        let nib = UINib(nibName: "PartyMemberCell", bundle: nil)
        membersTable.registerNib(nib, forCellReuseIdentifier: PartyMemberCellIdentifier)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController.visibleViewController.title = "Members"
        refresh()
    }
    
    // Copy pasta'd from Profile view controller to have the same kind of refresh logic
    // Keeping the commented out things for now to show what kind of changes were made for that
    // TODO: update the refresh to remove comments irrelevant to this controller when finished w/ it
    func refresh() {
        println("refreshing PartyMembersViewController")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                if LocalUser.sharedUser.party != nil {
                    if LocalParty.sharedParty.setup == true {
                        println("party is setup")
                        // Actually show members stuff
                        hideMessages()
                        hideMembersTable(false)
                        membersTable.reloadData()
                    } else {
                        showMessages("Well, this is awkward", detailLine: "We're not really sure what happened, try refreshing the party!")
                        hideMembersTable(true)
                    }
                } else {
                    showMessages("Not member of a party", detailLine: "Become a party member by joining or creating a party")
                    hideMembersTable(true)
                }
            } else {
                //setUserInfoHidden(true)
                //setStoriesTableToHidden(true)
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart One Sound")
                hideMembersTable(true)
                //disableButtons()
            }
        } else {
            //setUserInfoHidden(true)
            //setStoriesTableToHidden(true)
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use One Sound")
            hideMembersTable(true)
            //disableButtons()
        }
    }
    
    func hideMembersTable(hidden: Bool) {
        membersTable.hidden = hidden
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
    
    func hideMessages() {
        messageLabel1!.alpha = 0
        messageLabel1!.text = ""
        messageLabel2!.alpha = 0
        messageLabel2!.text = ""
    }
}

extension PartyMembersViewController: UITableViewDataSource {
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return LocalParty.sharedParty.members.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let membersCell = membersTable.dequeueReusableCellWithIdentifier(PartyMemberCellIdentifier, forIndexPath: indexPath) as PartyMemberCell
        
        if indexPath.row <= LocalParty.sharedParty.members.count {
            let user = LocalParty.sharedParty.members[indexPath.row]
            
            membersCell.userNameLabel.text = user.name
            membersCell.userUpvoteLabel.text = intFormattedToShortStringForDisplay(user.upvoteCount)
            membersCell.userSongLabel.text = intFormattedToShortStringForDisplay(user.songCount)
            //membersCell.userHotnessLabel.text = intFormattedToShortStringForDisplay(user.upvoteCount)
            membersCell.backgroundColor = user.colorToUIColor
            membersCell.userImage.image = UIImage(named: "guestUserImageForUserCell")
            
            if user.guest == false && user.photo != nil {
                membersCell.userImage.image = user.photo
            }
        }
        
        return membersCell
    }
}

extension PartyMembersViewController: UITableViewDelegate {
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 64.0
    }
}