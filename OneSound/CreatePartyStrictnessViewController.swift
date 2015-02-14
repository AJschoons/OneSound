//
//  CreatePartyStrictnessViewController.swift
//  OneSound
//
//  Created by adam on 8/13/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

protocol CreatePartyStrictnessViewControllerDelegate {
    func createPartyStrictnessViewController(partyStrictnessViewController: CreatePartyStrictnessViewController, didSelectStrictness selectedStrictness: PartyStrictnessOption)
}

class CreatePartyStrictnessViewController: UITableViewController {
    
    let cellLabelFontSize = 16
    let defaultCellReuseIdentifier = "defaultCell"
    let strictnessOptions: [PartyStrictnessOption] = [.Off, .Low, .Default, .Strict]
    var selectedStrictness: PartyStrictnessOption!
    var selectedIndex: Int!
    var delegate: CreatePartyStrictnessViewControllerDelegate?
    
    init(delegate initDelegate: CreatePartyStrictnessViewControllerDelegate, selectedStrictness strictness: PartyStrictnessOption) {
        delegate = initDelegate
        selectedStrictness = strictness
        super.init(style: UITableViewStyle.Grouped)
    }
    
    required init(coder aDecoder: NSCoder) {
        // Not actually used for anything
        delegate = nil
        selectedStrictness = .Default
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Grouped)
        
        navigationItem.title = "Strictness"
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
        
        // Creating an (empty) footer stops table from showing empty cells
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        tableView.scrollEnabled = true
        
        selectedIndex = find(strictnessOptions, selectedStrictness)
    }
    
}

extension CreatePartyStrictnessViewController: UITableViewDataSource {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return strictnessOptions.count
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Songs will not be skipped"
        case 1:
            return "Small groups of people"
        case 2:
            return "Average-sized groups of people"
        case 3:
            return "Large groups of people"
        default:
            return ""
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(defaultCellReuseIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        cell.textLabel!.text = strictnessOptions[indexPath.section].PartyStrictnessOptionToString()
        cell.textLabel!.font = UIFont.systemFontOfSize(CGFloat(cellLabelFontSize))
        
        // Sets check mark on cell with the currently selected color option
        if indexPath.section == selectedIndex {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return cell
    }
}

extension CreatePartyStrictnessViewController: UITableViewDelegate {
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Remove checkmark from previously selected cell
        let previousSelectedCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: selectedIndex))
        previousSelectedCell!.accessoryType = UITableViewCellAccessoryType.None
        
        // Update the selected index
        selectedIndex = indexPath.section
        
        // Add checkmark to selected cell
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        selectedCell!.accessoryType = UITableViewCellAccessoryType.Checkmark
        
        // Update the selectedStrictness, return that strictness to the delegate
        selectedStrictness = strictnessOptions[indexPath.section]
        delegate!.createPartyStrictnessViewController(self, didSelectStrictness: selectedStrictness)
    }
}