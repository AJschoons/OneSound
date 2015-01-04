//
//  PartyTabBarController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let PartyTabBarControllerNibName = "PartyTabBarController"

class PartyTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.barTintColor = UIColor.white()
        tabBar.tintColor = UIColor.blue()
        automaticallyAdjustsScrollViewInsets = false
        
        let partyMembersViewController = PartyMembersViewController(nibName: PartyMembersViewControllerNibName, bundle: nil)
        partyMembersViewController.tabBarItem.title = "Members"
        partyMembersViewController.tabBarItem.image = UIImage(named: "partyTabBarMembersIcon")
        
        let partyMainViewController = PartyMainViewController(nibName: PartyMainViewControllerNibName, bundle: nil)
        partyMainViewController.tabBarItem.title = "Now Playing"
        partyMainViewController.tabBarItem.image = UIImage(named: "partyTabBarPartyIcon")
        
        let partySongsViewController = PartySongsViewController(nibName: PartySongsViewControllerNibName, bundle: nil)
        partySongsViewController.tabBarItem.title = "Playlist"
        partySongsViewController.tabBarItem.image = UIImage(named: "partyTabBarSongsIcon")
        
        viewControllers = [partyMembersViewController, partyMainViewController,
            partySongsViewController]
        selectedIndex = 1
        title = "Party"
    }
    
    override func viewWillAppear(animated: Bool) {
        let fnc = getFrontNavigationController()
        let sideMenuButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: fnc, action: "toggleSideMenu")
        navigationItem.leftBarButtonItem = sideMenuButtonItem
    
        // Refresh the item at the selected index
        // Otherwise they'd only refresh when another tab is selected, and not when 
        // navigated from the side menu
        switch selectedIndex {
        case 0:
            let partyMembersViewController = viewControllers![0] as PartyMembersViewController
            partyMembersViewController.viewWillAppear(animated)
        case 1:
            let partyMainViewController = viewControllers![1] as PartyMainViewController
            partyMainViewController.viewWillAppear(animated)
        case 2:
            let partySongsViewController = viewControllers![2] as PartySongsViewController
            partySongsViewController.viewWillAppear(animated)
        default:
            println("ERROR: selectedIndex for PartyTabBarController was out of range 0-2")
        }
    }
    
    // If the PartyMainViewController is the selected tab, change the right bar button to its rightBarButton
    func updateRightBarButtonForMainParty() {
        if let pMainVC = selectedViewController as? PartyMainViewController {
            navigationItem.rightBarButtonItem = pMainVC.rightBarButton
            if pMainVC.rightBarButton == pMainVC.createPartyButton {
                // Disabled when guest
                navigationItem.rightBarButtonItem!.enabled = !UserManager.sharedUser.guest
            }
        }
    }
}

extension PartyTabBarController: UITabBarControllerDelegate {
    func tabBarController(tabBarController: UITabBarController!, didSelectViewController viewController: UIViewController!) {
        if let ptbc = tabBarController as? PartyTabBarController {
            if let pMembVC = viewController as? PartyMembersViewController {
                ptbc.navigationItem.rightBarButtonItem = nil
            } else if let pMainVC = viewController as? PartyMainViewController {
                ptbc.navigationItem.rightBarButtonItem = pMainVC.rightBarButton
            } else if let pSongVC = viewController as? PartySongsViewController {
                ptbc.navigationItem.rightBarButtonItem = pSongVC.addSongButton
            } else {
                println("selected a tab that wasn't in the PartyTabBarController")
            }
        } else {
            println("selected a TabBarController that wasn't the PartyTabBarController")
        }
    }
}