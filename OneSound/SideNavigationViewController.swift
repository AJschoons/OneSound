//
//  SideNavigationController.swift
//  OneSound
//
//  Created by adam on 7/10/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SideNavigationViewController: UITableViewController {
    
    let navMenuCellIdentifier = "navMenuCell"
    let topCellIdentifier = "topCell"
    var topCellHeight: CGFloat = 150

    override func viewDidLoad() {
        super.viewDidLoad()

        //tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: navMenuCellIdentifier)
    }
}

extension SideNavigationViewController: UITableViewDataSource {
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell? {
       // let cell = tableView.dequeueReusableCellWithIdentifier(navMenuCellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        let cell = UITableViewCell()
        
        if indexPath.row == 0 {
            cell.backgroundColor = UIColor.greenColor()
        }
        
        // Configure the cell...
        
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
}
