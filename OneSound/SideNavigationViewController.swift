//
//  SideNavigationController.swift
//  OneSound
//
//  Created by adam on 7/10/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SideNavigationViewController: UITableViewController {
    
    let menuCellIdentifier = "sideNavigationMenuCell"
    let userCellIdentifier = "sideNavigationUserCell"
    var topCellHeight: CGFloat = 150
    var sideMenuSelectedIcons = [UIImage]()
    var sideMenuUnselectedIcons = [UIImage]()
    var sideMenuItemLabels = [String]()
    var userCell: SideNavigationUserCell?
    
    var pL = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearsSelectionOnViewWillAppear = false
        
        // Customize the tableView
        tableView.scrollEnabled = false
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        //tableView
        
        // These arrays have a dummy item in the first index so menu cell attributes can be set
        // by cell row (otherwise having the first cell be a different type would make indexing
        // less clear)
        sideMenuSelectedIcons = [UIImage(), UIImage(named: "sideMenuPartyIconSelected"),
            UIImage(named: "sideMenuHistoryIconSelected"), UIImage(named: "sideMenuSearchIconSelected"),
            UIImage(named: "sideMenuFollowingIconSelected"), UIImage(named: "sideMenuStoriesIconSelected"),
            UIImage(named: "sideMenuProfileIconSelected")]
        sideMenuUnselectedIcons = [UIImage(), UIImage(named: "sideMenuPartyIconUnselected"),
            UIImage(named: "sideMenuHistoryIconUnselected"), UIImage(named: "sideMenuSearchIconUnselected"),
            UIImage(named: "sideMenuFollowingIconUnselected"), UIImage(named: "sideMenuStoriesIconUnselected"),
            UIImage(named: "sideMenuProfileIconUnselected")]
        sideMenuItemLabels = ["", "Party", "History", "Search", "Following", "Stories", "Profile"]
        
        // Register the cells
        var nib = UINib(nibName: "SideNavigationMenuCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: menuCellIdentifier)
        
        nib = UINib(nibName: "SideNavigationUserCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: userCellIdentifier)
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
            userCell = cell
        } else {
            // If a menu cell
            let menuCell = tableView.dequeueReusableCellWithIdentifier(menuCellIdentifier, forIndexPath: indexPath) as SideNavigationMenuCell
            menuCell.sideMenuItemLabel.text = sideMenuItemLabels[indexPath.row]
            menuCell.selectedIcon = sideMenuSelectedIcons[indexPath.row]
            menuCell.unselectedIcon = sideMenuUnselectedIcons[indexPath.row]
            menuCell.sideMenuItemIcon.image = menuCell.unselectedIcon
            
            cell = menuCell
        }
        
        return cell
    }
}

extension SideNavigationViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if indexPath.row == 0   {
            return topCellHeight
        } else {
            return ((view.window.bounds.height - topCellHeight - 20) / 6.0)
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
