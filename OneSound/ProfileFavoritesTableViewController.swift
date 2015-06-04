//
//  ProfileFavoritesTableViewController.swift
//  OneSound
//
//  Created by adam on 6/3/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

class ProfileFavoritesTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension ProfileFavoritesTableViewController: UITableViewDataSource {
    // MARK: Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return 10
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

        // Configure the cell...
        cell.backgroundColor = UIColor.red()

        return cell
    }
}
