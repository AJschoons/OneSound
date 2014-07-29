//
//  PartyTabBarController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class PartyTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.barTintColor = UIColor.white()
        tabBar.tintColor = UIColor.blue()
        tabBar.translucent = false
        
        let partyMembersViewController = PartyMembersViewController()
        partyMembersViewController.tabBarItem.title = "Members"
        partyMembersViewController.tabBarItem.image = UIImage(named: "partyTabBarMembersIcon")
        
        let partyMainViewController = PartyMainViewController()
        partyMainViewController.tabBarItem.title = "Party"
        partyMainViewController.tabBarItem.image = UIImage(named: "partyTabBarPartyIcon")
        
        let partySongsViewController = PartySongsViewController()
        partySongsViewController.tabBarItem.title = "Songs"
        partySongsViewController.tabBarItem.image = UIImage(named: "partyTabBarSongsIcon")
        
        viewControllers = [partyMembersViewController, partyMainViewController,
            partySongsViewController]
        selectedIndex = 1
        title = "Party"
    }
    
    override func viewWillAppear(animated: Bool) {
        // Setup the revealViewController to work for this view controller,
        // add its sideMenu icon to the nav bar
        let revealController = revealViewController()
        revealController.panGestureRecognizer()
        revealController.tapGestureRecognizer()
        let revealButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: revealController, action: "revealToggle:")
        navigationItem.leftBarButtonItem = revealButtonItem
        
        // Refresh the item at the selected index
        // Otherwise they'd only refresh when another tab is selected, and not when 
        // navigated from the side menu
        switch selectedIndex {
        case 0:
            (viewControllers[0] as PartyMembersViewController).viewWillAppear(animated)
        case 1:
            (viewControllers[1] as PartyMainViewController).viewWillAppear(animated)
        case 2:
            (viewControllers[2] as PartySongsViewController).viewWillAppear(animated)
        default:
            println("ERROR: selectedIndex for PartyTabBarController was out of range 0-2")
        }
    }
}