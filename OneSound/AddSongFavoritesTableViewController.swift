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
    weak var parentAddSongViewController: UIViewController?
    
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedSong = dataHelper.userFavoritesManager.pagedDataArray.data[indexPath.row]
        let source = "sc"
        
        if UserManager.sharedUser.setup == true {
            let partyManager = PartyManager.sharedParty
            if partyManager.state != .None {
                
                //TODO: NIGGA MAKE DURATION WORK
                
                OSAPI.sharedClient.POSTSong(PartyManager.sharedParty.partyID, externalID: selectedSong.externalID!.toInt()!, source: source, title: selectedSong.name, artist: selectedSong.artistName, duration: 500, artworkURL: selectedSong.artworkURL,
                    success: { data, responseObject in
                        // If no song playing when song added, bring them to the Now Playing tab
                        if !partyManager.hasCurrentSongAndUser && partyManager.state == .HostStreamable {
                            getPartyTabBarController()?.selectedIndex = 1
                        }
                        
                        self.parentAddSongViewController?.dismissViewControllerAnimated(true, completion: nil)
                        
                        NSNotificationCenter.defaultCenter().postNotificationName(PartySongWasAddedNotification, object: nil)
                    }, failure: { task, error in
                        self.parentAddSongViewController?.dismissViewControllerAnimated(true, completion: nil)
                        let alert = UIAlertView(title: "Problem Adding Song", message: "The song could not be added to the playlist, please try a different song", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                        alert.show()
                    }
                )
            } else {
                let alert = UIAlertView(title: "Not A Party Member", message: "Please join a party before adding a song", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.show()
            }
        } else {
            let alert = UIAlertView(title: "Not Signed In", message: "Please sign into an account before adding a song", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
            alert.show()
        }

    }
}
