//
//  AddSongFavoritesTableViewController.swift
//  OneSound
//
//  Created by Tanay Salpekar on 6/7/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

class AddSongFavoritesTableViewController: OSViewController {

    let dataHelper = UserFavoritesTableDataHelper()
    let TableViewHeaderHeight: CGFloat = 20.0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Setup data helper
        dataHelper.delegate = self
        dataHelper.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        dataHelper.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        dataHelper.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        dataHelper.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        dataHelper.viewDidDisappear(animated)
    }
    

    /*
    // MARK: - Navigation
    */

}

extension AddSongFavoritesTableViewController: UserFavoritesTableDataHelperDelegate
{
    // MARK: UserFavoritesTableDataHelperDelegate
    
    func rightUtilityButtonsForCellAtIndexPath(indexPath: NSIndexPath) -> [AnyObject]
    {
        return NSMutableArray() as [AnyObject]
    }
    
    // Click event on right utility button of a cell
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex rightButtonsIndex: NSInteger)
    {
        
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
}
