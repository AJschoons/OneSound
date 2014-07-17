//
//  LoginColorViewController.swift
//  OneSound
//
//  Created by adam on 7/16/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

protocol LoginColorViewControllerDelegate {
    func loginColorViewController(loginColorviewController: LoginColorViewController, didSelectColor: OneSoundColorOption)
}

class LoginColorViewController: UITableViewController {
    
    let colorCellReuseIdentifier = "colorCell"
    let colorNames: [OneSoundColorOption] = [.Random, .Green, .Turquiose, .Purple, .Red, .Orange, .Yellow]
    let colorViewColors: [UIColor?] = [nil, UIColor.green(), UIColor.turquoise(), UIColor.purple(),
                                        UIColor.red(), UIColor.orange(), UIColor.yellow()]
    var selectedColor: OneSoundColorOption
    var selectedIndex: Int!
    var delegate: LoginColorViewControllerDelegate
    
    init(delegate initDelegate: LoginColorViewControllerDelegate, selectedColor color: OneSoundColorOption) {
        delegate = initDelegate
        selectedColor = color
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Choose Color"
        
        let nib = UINib(nibName: "LoginColorCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: colorCellReuseIdentifier)
        // Creating an (empty) foot stops table from showing empty cells
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        tableView.scrollEnabled = false
        
        selectedIndex = find(colorNames, selectedColor)
        println("viewDidLoad: selectedIndex is \(selectedIndex)")
    }

}

extension LoginColorViewController: UITableViewDataSource {
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return colorNames.count
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(colorCellReuseIdentifier, forIndexPath: indexPath) as LoginColorCell
        cell.colorLabel.text = colorNames[indexPath.row].toRaw()
        cell.colorView.backgroundColor = colorViewColors[indexPath.row]
        
        // Sets check mark on cell with the currently selected color option
        if indexPath.row == selectedIndex {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return cell
    }
}

extension LoginColorViewController: UITableViewDelegate {
    override func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 44
    }
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        // Remove checkmark from previously selected cell
        let previousSelectedCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedIndex, inSection: 0))
        previousSelectedCell.accessoryType = UITableViewCellAccessoryType.None
        
        // Update the selected index
        selectedIndex = indexPath.row
        
        // Add checkmark to selected cell
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        selectedCell.accessoryType = UITableViewCellAccessoryType.Checkmark
        
        // Update the selectedColor, return that color to the delegate
        selectedColor = colorNames[indexPath.row]
        delegate.loginColorViewController(self, didSelectColor: selectedColor)
    }
}