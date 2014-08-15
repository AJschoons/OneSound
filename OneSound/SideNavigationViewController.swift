//
//  SideNavigationController.swift
//  OneSound
//
//  Created by adam on 7/10/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SideNavigationViewController: UITableViewController {
    
    //enum SideMenuRow: Int {
    //    case Party = 1, History, Search, Following, Stories, Profile
    //}
    
    let menuCellIdentifier = "sideNavigationMenuCell"
    let userCellIdentifier = "sideNavigationUserCell"
    var topCellHeight: CGFloat = 150
    var sideMenuSelectedIcons = [UIImage?]()
    var sideMenuUnselectedIcons = [UIImage?]()
    var sideMenuItemLabels = [String?]()
    var userCell: SideNavigationUserCell?
    var menuViewControllers: [UIViewController?] = [nil, PartyTabBarController(nibName: PartyTabBarControllerNibName, bundle: nil), HistoryViewController(nibName: HistoryViewControllerNibName, bundle: nil),
        SearchViewController(nibName: SearchViewControllerNibName, bundle: nil), FollowingViewController(nibName: FollowingViewControllerNibName, bundle: nil), FrontViewController(nibName: FrontViewControllerNibName, bundle: nil),
        ProfileViewController(nibName: ProfileViewControllerNibName, bundle: nil)]
    
    // TODO: have this be saved when app closes
    var initiallySelectedRow = 6
    
    var pL = true
    var firstTimeAppearing = true

    override func viewDidLoad() {
        /*
        let fnc = (UIApplication.sharedApplication().delegate as AppDelegate).revealViewController!.frontViewController as FrontNavigationController
        let viewControllerToNavTo = menuViewControllers[initiallySelectedRow]!
        let loggingInSplashViewController = LoggingInSpashViewController(nibName: LoggingInSpashViewControllerNibName, bundle: nil)
        fnc.setViewControllers([viewControllerToNavTo, loggingInSplashViewController], animated: false)
        */

        super.viewDidLoad()
        
        clearsSelectionOnViewWillAppear = false
        
        // Customize the tableView
        tableView.scrollEnabled = false
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        // First items are nil so index match table table row
        sideMenuSelectedIcons = [nil, UIImage(named: "sideMenuPartyIconSelected"),
            UIImage(named: "sideMenuHistoryIconSelected"), UIImage(named: "sideMenuSearchIconSelected"),
            UIImage(named: "sideMenuFollowingIconSelected"), UIImage(named: "sideMenuStoriesIconSelected"),
            UIImage(named: "sideMenuProfileIconSelected")]
        sideMenuUnselectedIcons = [nil, UIImage(named: "sideMenuPartyIconUnselected"),
            UIImage(named: "sideMenuHistoryIconUnselected"), UIImage(named: "sideMenuSearchIconUnselected"),
            UIImage(named: "sideMenuFollowingIconUnselected"), UIImage(named: "sideMenuStoriesIconUnselected"),
            UIImage(named: "sideMenuProfileIconUnselected")]
        sideMenuItemLabels = [nil, "Party", "History", "Search", "Following", "Stories", "Profile"]
        
        // Register the cells
        var nib = UINib(nibName: "SideNavigationMenuCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: menuCellIdentifier)
        
        nib = UINib(nibName: "SideNavigationUserCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: userCellIdentifier)
    }
    
    override func viewWillAppear(animated: Bool) {
        // Update the user cell when it appears
        if userCell != nil {
            userCell!.refresh()
        }
        super.viewWillAppear(animated)
    }
    
    func programaticallySelectRow(row: Int) {
        let indexPath = NSIndexPath(forRow: row, inSection: 0)
        tableView(tableView, didSelectRowAtIndexPath: indexPath)
    }
}

extension SideNavigationViewController: UITableViewDataSource {
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell? {
        printlnC(pL, pG, "SideNavigationViewController: cellForRowAtIndexPath")
        var cell: UITableViewCell?
        
        if indexPath.row == 0 {
            // If the user cell
            cell = tableView.dequeueReusableCellWithIdentifier(userCellIdentifier, forIndexPath: indexPath) as SideNavigationUserCell
            userCell = (cell as SideNavigationUserCell)
        } else {
            // If a menu cell
            let menuCell = tableView.dequeueReusableCellWithIdentifier(menuCellIdentifier, forIndexPath: indexPath) as SideNavigationMenuCell
            menuCell.sideMenuItemLabel.text = sideMenuItemLabels[indexPath.row]
            menuCell.selectedIcon = sideMenuSelectedIcons[indexPath.row]
            menuCell.unselectedIcon = sideMenuUnselectedIcons[indexPath.row]
            menuCell.sideMenuItemIcon.image = menuCell.unselectedIcon
            
            if firstTimeAppearing && indexPath.row == initiallySelectedRow {
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
                firstTimeAppearing = false
            }
            
            cell = menuCell
        }
        
        return cell
    }
}

extension SideNavigationViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        
        // If a menu row
        if indexPath.row > 0 {
            let revealViewController = (UIApplication.sharedApplication().delegate as AppDelegate).revealViewController
            let fnc = revealViewController!.frontViewController as FrontNavigationController
            
            let menuViewController = menuViewControllers[indexPath.row]!
            fnc.setViewControllers([menuViewController], animated: false)
            
            // Animate to FrontNavigationController; hide SideNavigation
            revealViewController!.setFrontViewPosition(FrontViewPositionLeft, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if indexPath.row == 0   {
            return topCellHeight
        } else {
            return ((view.window!.bounds.height - topCellHeight - 20) / 6.0)
        }
    }
    
    override func tableView(tableView: UITableView!, shouldHighlightRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        if indexPath.row == 0 {
            return false
        } else {
            return true
        }
    }
}
