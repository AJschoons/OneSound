//
//  SideNavigationController.swift
//  OneSound
//
//  Created by adam on 7/10/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

enum SideMenuRow: Int {
    case Party = 1, Search, Profile
}

class SideNavigationViewController: UITableViewController {
    
    let menuCellIdentifier = "sideNavigationMenuCell"
    let userCellIdentifier = "sideNavigationUserCell"
    var topCellHeight: CGFloat = 150
    var sideMenuIcons = [UIImage?]()
    var sideMenuItemLabels = [String?]()
    var userCell: SideNavigationUserCell?
    var menuViewControllers: [UIViewController?] = [nil, PartyTabBarController(nibName: PartyTabBarControllerNibName, bundle: nil), SearchViewController(nibName: SearchViewControllerNibName, bundle: nil), ProfileViewController(nibName: ProfileViewControllerNibName, bundle: nil)]
    
    
    // TODO: have this be saved when app closes
    var initiallySelectedRow = 3
    
    var pL = true
    var firstTimeAppearing = true

    override func viewDidLoad() {
        let fnc = getFrontNavigationController()
        let sideMenuButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: fnc, action: "toggleSideMenu")
        navigationItem.leftBarButtonItem = sideMenuButtonItem

        super.viewDidLoad()
        
        clearsSelectionOnViewWillAppear = false
        
        // Customize the tableView
        tableView.scrollEnabled = false
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        // Used to shift info down below nav bar
        tableView.contentInset = UIEdgeInsetsMake(64.0, 0, 0, 0)
        
        var shouldUseGrayIcons = false
        if ObjCUtilities.checkIfClassExists("UIVisualEffectView") {
            // iOS 8 has blurred menu
            tableView.backgroundColor = UIColor.clearColor()
        } else {
            // iOS 7 has static white menu
            tableView.backgroundColor = UIColor.whiteColor()
            shouldUseGrayIcons = true
        }
        
        // First items are nil so index match table table row
        if shouldUseGrayIcons {
            sideMenuIcons = [nil, UIImage(named: "sideMenuPartyIconGray"), UIImage(named: "sideMenuSearchIconGray"), UIImage(named: "sideMenuProfileIconGray")]
        } else {
            sideMenuIcons = [nil, UIImage(named: "sideMenuPartyIconBlack"), UIImage(named: "sideMenuSearchIconBlack"), UIImage(named: "sideMenuProfileIconBlack")]
        }

        sideMenuItemLabels = [nil, "Party", "Party Search", "Profile"]
        
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
        
        // Select the row, deselect all the other rows
        for var i = 1; i < tableView.numberOfRowsInSection(0); ++i {
            let menuCellIndexPath = NSIndexPath(forRow: i, inSection: 0)
            let menuCell = tableView.cellForRowAtIndexPath(menuCellIndexPath)
            
            if menuCell != nil {
                let selected = (i == row)
                menuCell!.setSelected(selected, animated: false)
            }
        }
        
        let indexPath = NSIndexPath(forRow: row, inSection: 0)
        tableView(tableView, didSelectRowAtIndexPath: indexPath)
        //tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
        
    }
}

extension SideNavigationViewController: UITableViewDataSource {
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuViewControllers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        println("SideNavigationViewController: cellForRowAtIndexPath")
        var cell: UITableViewCell?
        
        if indexPath.row == 0 {
            // If the user cell
            cell = tableView.dequeueReusableCellWithIdentifier(userCellIdentifier, forIndexPath: indexPath) as! SideNavigationUserCell
            userCell = (cell as! SideNavigationUserCell)
        } else {
            // If a menu cell
            let menuCell = tableView.dequeueReusableCellWithIdentifier(menuCellIdentifier, forIndexPath: indexPath) as! SideNavigationMenuCell
            menuCell.sideMenuItemLabel.text = sideMenuItemLabels[indexPath.row]
            menuCell.sideMenuItemIcon.image = sideMenuIcons[indexPath.row]
            
            if firstTimeAppearing && indexPath.row == initiallySelectedRow {
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
                firstTimeAppearing = false
            }
            
            cell = menuCell
        }
        
        return cell!
    }
}

extension SideNavigationViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // If a menu row
        if indexPath.row > 0 {
            // Select the row, deselect all the other rows
            for var i = 1; i < tableView.numberOfRowsInSection(0); ++i {
                let menuCellIndexPath = NSIndexPath(forRow: i, inSection: 0)
                let menuCell = tableView.cellForRowAtIndexPath(menuCellIndexPath)
                
                if menuCell != nil {
                    let selected = i == indexPath.row
                    menuCell!.setSelected(selected, animated: false)
                }
            }
        
            let menuViewController = menuViewControllers[indexPath.row]!
            let fnc = getFrontNavigationController()
            fnc?.setContentViewController(menuViewController)
            fnc?.sideMenu?.hideSideMenu()
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0   {
            return topCellHeight
        } else {
            if let window = view.window {
                // = windowHeight - topCellHeight - statusBarHeight - navBarHeight
                //let height = (view.window!.bounds.height - topCellHeight - 20 - 64) / 6.0
                return 50
            }
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        } else {
            return true
        }
    }
}
