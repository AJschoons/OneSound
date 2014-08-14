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
    
    let defaultCellReuseIdentifier = "defaultCell"
    let strictnessOptions: [PartyStrictnessOption] = [.Off, .Low, .Default, .Strict]
    var selectedStrictness: PartyStrictnessOption!
    var selectedIndex: Int!
    var delegate: CreatePartyStrictnessViewControllerDelegate?
    
    init(delegate initDelegate: CreatePartyStrictnessViewControllerDelegate, selectedStrictness strictness: PartyStrictnessOption) {
        delegate = initDelegate
        selectedStrictness = strictness
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder!) {
        // TODO: find a way to actually save the delegate in color; simply forced to do this for now so did this garbage work
        delegate = nil
        selectedStrictness = .Default
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Grouped)
        
        navigationItem.title = "Choose Strictness"
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
        
        // Creating an (empty) footer stops table from showing empty cells
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        if UIScreen.mainScreen().bounds.height > 500 {
            tableView.scrollEnabled = false
        } else {
            tableView.scrollEnabled = true
        }
        
        selectedIndex = find(strictnessOptions, selectedStrictness)
    }
    
}

extension CreatePartyStrictnessViewController: UITableViewDataSource {
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return strictnessOptions.count
    }
    
    override func tableView(tableView: UITableView!, titleForFooterInSection section: Int) -> String! {
        switch section {
        case 0:
            return "Songs will not be skipped"
        case 1:
            return "Small groups of people. Skipping a song takes 4/5 of its votes being down, or 2/3 of party members down voting it"
        case 2:
            return "Average-sized groups of people. Skipping a song takes 2/3 of its votes being down, or 2/5 of party members down voting it"
        case 3:
            return "Large groups of people. Skipping a song takes 1/2 of its votes being down, or 1/4 of party members down voting it"
        default:
            return ""
        }
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(defaultCellReuseIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel.text = strictnessOptions[indexPath.section].PartyStrictnessOptionToString()
        
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
    override func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 44
    }
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        // Remove checkmark from previously selected cell
        let previousSelectedCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: selectedIndex))
        previousSelectedCell.accessoryType = UITableViewCellAccessoryType.None
        
        // Update the selected index
        selectedIndex = indexPath.section
        
        // Add checkmark to selected cell
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        selectedCell.accessoryType = UITableViewCellAccessoryType.Checkmark
        
        // Update the selectedStrictness, return that strictness to the delegate
        selectedStrictness = strictnessOptions[indexPath.section]
        delegate!.createPartyStrictnessViewController(self, didSelectStrictness: selectedStrictness)
    }
}