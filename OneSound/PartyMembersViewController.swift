//
//  PartyMembersViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let PartyMembersViewControllerNibName = "PartyMembersViewController"
let PartyMemberCellIdentifier = "PartyMemberCell"

class PartyMembersViewController: UIViewController {
    
    let userThumbnailImageCache = (UIApplication.sharedApplication().delegate as AppDelegate).userThumbnailImageCache
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    
    @IBOutlet weak var membersTable: UITableView!
    
    override func viewDidLoad() {
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        
        // Creating an (empty) footer stops table from showing empty cells
        membersTable.tableFooterView = UIView(frame: CGRectZero)
        
        let nib = UINib(nibName: PartyMemberCellNibName, bundle: nil)
        membersTable.registerNib(nib, forCellReuseIdentifier: PartyMemberCellIdentifier)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.visibleViewController.title = "Members"
        refresh()
    }
    
    func reloadTableData() {
        membersTable.reloadData()
    }
    
    // Copy pasta'd from Profile view controller to have the same kind of refresh logic
    // Keeping the commented out things for now to show what kind of changes were made for that
    // TODO: update the refresh to remove comments irrelevant to this controller when finished w/ it
    func refresh() {
        println("refreshing PartyMembersViewController")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                if LocalUser.sharedUser.party != nil && LocalUser.sharedUser.party != 0 {
                    if LocalParty.sharedParty.setup == true {
                        // Actually show members stuff
                        hideMessages()
                        hideMembersTable(false)
                        
                        LocalParty.sharedParty.updatePartyMembers(LocalParty.sharedParty.partyID!,
                            completion: {
                                self.membersTable.reloadData()
                                self.loadImagesForOnScreenRows()
                            }
                        )
                    } else {
                        showMessages("Well, this is awkward", detailLine: "We're not really sure what happened, try refreshing the party!")
                        hideMembersTable(true)
                    }
                } else {
                    showMessages("Not member of a party", detailLine: "Become a party member by joining or creating a party")
                    hideMembersTable(true)
                }
            } else {
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
                hideMembersTable(true)
            }
        } else {
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
            hideMembersTable(true)
        }
    }
    
    func hideMembersTable(hidden: Bool) {
        membersTable.hidden = hidden
    }
    
    func showMessages(mainLine: String?, detailLine: String?) {
        if mainLine != nil {
            messageLabel1!.alpha = 1
            messageLabel1!.text = mainLine
        }
        if detailLine != nil {
            messageLabel2!.alpha = 1
            messageLabel2!.text = detailLine
        }
    }
    
    func hideMessages() {
        messageLabel1!.alpha = 0
        messageLabel1!.text = ""
        messageLabel2!.alpha = 0
        messageLabel2!.text = ""
    }
}

extension PartyMembersViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocalParty.sharedParty.members.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let membersCell = membersTable.dequeueReusableCellWithIdentifier(PartyMemberCellIdentifier, forIndexPath: indexPath) as PartyMemberCell
        
        if indexPath.row <= LocalParty.sharedParty.members.count {
            let user = LocalParty.sharedParty.members[indexPath.row]
            
            setUserInfoLabelsText(upvoteLabel: membersCell.userUpvoteLabel, numUpvotes: user.upvoteCount, songLabel: membersCell.userSongLabel, numSongs: user.songCount, hotnessLabel: membersCell.userHotnessLabel, percentHotness: user.hotnessPercent, userNameLabel: membersCell.userNameLabel, userName: user.name)
            
            membersCell.backgroundColor = user.colorToUIColor
            membersCell.userImage.image = guestUserImageForUserCell
            
            if user.guest == false && user.photoURL != nil {
                if tableView.dragging == false && tableView.decelerating == false {
                    
                    userThumbnailImageCache.queryDiskCacheForKey(user.photoURL!,
                        done: { image, imageCacheType in
                            if image != nil {
                                let updateCell = self.membersTable.cellForRowAtIndexPath(indexPath) as? PartyMemberCell
                                
                                if updateCell != nil {
                                    // If the cell for that row is still visible and correct
                                    updateCell!.userImage.image = image
                                    updateCell!.setNeedsLayout()
                                }
                            } else {
                                self.startImageDownload(user.photoURL!, forIndexPath: indexPath)
                            }
                        }
                    )
                    
                }
            } else {
                membersCell.userImage.image = guestUserImageForUserCell
            }
        }
        
        return membersCell
    }
    
    func startImageDownload(urlString: String, forIndexPath indexPath: NSIndexPath) {
        
        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: urlString), options: nil, progress: nil,
            completed: { image, error, cacheType, boolValue, url in
                // Make sure it's still the correct cell
                let updateCell = self.membersTable.cellForRowAtIndexPath(indexPath) as? PartyMemberCell
                
                if updateCell != nil {
                    // If the cell for that row is still visible and correct
                    
                    if error == nil && image != nil {
                        let processedImage = cropBiggestCenteredSquareImageFromImage(image, sideLength: updateCell!.userImage.frame.width)
                        
                        self.userThumbnailImageCache.storeImage(processedImage, forKey: urlString)
                        
                        dispatchAsyncToMainQueue(action: {
                            updateCell!.userImage.image = processedImage
                            updateCell!.userImage.setNeedsLayout()
                        })
                        //updateCell!.songImage.setNeedsLayout()
                    } else {
                        dispatchAsyncToMainQueue(action: {
                            updateCell!.userImage.image = guestUserImageForUserCell
                            updateCell!.userImage.setNeedsLayout()
                        })
                    }
                }
            }
        )
    }
    
    func loadImagesForOnScreenRows() {
        let visiblePaths = membersTable.indexPathsForVisibleRows() as [NSIndexPath]
        
        for path in visiblePaths {
            let user = LocalParty.sharedParty.members[path.row]
            
            if user.photoURL != nil {
                userThumbnailImageCache.queryDiskCacheForKey(user.photoURL!,
                    done: { image, imageCacheType in
                        if image != nil {
                            let updateCell = self.membersTable.cellForRowAtIndexPath(path) as? PartyMemberCell
                            
                            if updateCell != nil {
                                // If the cell for that row is still visible and correct
                                updateCell!.userImage.image = image
                                updateCell!.userImage.setNeedsLayout()
                            }
                        } else {
                            self.startImageDownload(user.photoURL!, forIndexPath: path)
                        }
                    }
                )
            } else {
                let updateCell = self.membersTable.cellForRowAtIndexPath(path) as? PartyMemberCell
                
                if updateCell != nil {
                    // If the cell for that row is still visible and correct
                    updateCell!.userImage.image = guestUserImageForUserCell
                }
            }
        }
    }
}

extension PartyMembersViewController: UITableViewDelegate {
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 64.0
    }
}

extension PartyMembersViewController: UIScrollViewDelegate {
    // Load the images for all onscreen rows when scrolling is finished
    
    // Called on finger up if the user dragged. Decelerate is true if it will continue moving afterwards
    func scrollViewDidEndDragging(scrollView: UIScrollView!, willDecelerate decelerate: Bool) {
        // Load the images for the cells if it won't be moving afterwards
        if !decelerate {
            loadImagesForOnScreenRows()
        }
    }
    
    // Called when the scroll view grinds to a halt
    func scrollViewDidEndDecelerating(scrollView: UIScrollView!) {
        loadImagesForOnScreenRows()
    }
}

/*
extension PartyMembersViewController: SDWebImageManagerDelegate {
    func imageManager(imageManager: SDWebImageManager!, transformDownloadedImage image: UIImage!, withURL imageURL: NSURL!) -> UIImage! {
        println("transforming downloaded image")
        return cropBiggestCenteredSquareImageFromImage(image, sideLength: 50)
    }
}
*/