//
//  ProfileFavoritesTableViewController.swift
//  OneSound
//
//  Created by adam on 6/3/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

class ProfileFavoritesTableViewController: OSViewController
{
    let dataHelper = UserFavoritesTableDataHelper()
    let TableViewHeaderViewNibName = "UserFavoritesTableHeaderView"
    let TableViewHeaderHeight: CGFloat = 25.0
    
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
}

extension ProfileFavoritesTableViewController: UserFavoritesTableDataHelperDelegate
{
    // MARK: UserFavoritesTableDataHelperDelegate
    
    func rightUtilityButtonsForCellAtIndexPath(indexPath: NSIndexPath) -> [AnyObject]
    {
        let rightUtilityButtons = NSMutableArray()
        rightUtilityButtons.sw_addUtilityButtonWithColor(UIColor.red(), icon: UIImage(named: "trashIcon"))
        
        return rightUtilityButtons as [AnyObject]
    }
    
    // Click event on right utility button of a cell
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex rightButtonsIndex: NSInteger)
    {
        // Delete the favorite button
        if rightButtonsIndex == 0
        {
            if let cellIndexPath = dataHelper.tableView.indexPathForCell(cell)
            {
                cell.hideUtilityButtonsAnimated(true)
                
                // Unfavorite the song
                let favorites = dataHelper.userFavoritesManager.pagedDataArray.data
                PartyManager.sharedParty.songUnfavorite(favorites[cellIndexPath.row].songID)
                
                // Remove from favorites and reload
                dataHelper.userFavoritesManager.pagedDataArray.removeDataAtIndex(cellIndexPath.row)
                dataHelper.tableView.beginUpdates()
                dataHelper.tableView.deleteRowsAtIndexPaths([cellIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                dataHelper.tableView.endUpdates()
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return TableViewHeaderHeight
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let headerView = UIView.loadFromNibNamed(TableViewHeaderViewNibName)
        headerView!.backgroundColor = refreshControlBackgroundColor()
        headerView!.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: TableViewHeaderHeight)
        return headerView
    }
    
    func refreshControlBackgroundColor() -> UIColor
    {
        return UIColor.grayMid()
    }
    
    func refreshControlTintColor() -> UIColor
    {
        return UIColor.grayDark()
    }
}
