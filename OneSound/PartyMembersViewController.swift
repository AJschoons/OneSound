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
    let membersManager = PartyManager.sharedParty.membersManager
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    
    @IBOutlet weak var membersTable: UITableView!
    
    var tableViewController: UITableViewController!
    
    let heightForRows: CGFloat = 64.0
    
    override func viewDidLoad() {
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshIfVisible", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and UserManager is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshIfVisible", name: UserManagerInformationDidChangeNotification, object: nil)
        
        // Creating an (empty) footer stops table from showing empty cells
        membersTable.tableFooterView = UIView(frame: CGRectZero)
        
        let nib = UINib(nibName: PartyMemberCellNibName, bundle: nil)
        membersTable.registerNib(nib, forCellReuseIdentifier: PartyMemberCellIdentifier)
        
        // Setup the refresh control
        // Added and placed inside a UITableViewController to remove "stutter" from having a
        // UIViewController handle the refresh control
        // http://stackoverflow.com/questions/12497940/uirefreshcontrol-without-uitableviewcontroller
        tableViewController = UITableViewController(style: UITableViewStyle.Plain)
        tableViewController.tableView = membersTable
        addChildViewController(tableViewController)
        tableViewController.refreshControl = UIRefreshControl()
        tableViewController.refreshControl!.backgroundColor = UIColor.blue()
        tableViewController.refreshControl!.tintColor = UIColor.white()
        tableViewController.refreshControl!.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        tableViewController.automaticallyAdjustsScrollViewInsets = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        parentViewController!.navigationItem.title = "Members"
        
        // Allows cells to flow under nav bar and tab bar, but not stop scrolling behind them when content stops
        membersTable.contentInset = UIEdgeInsetsMake(65, 0, 49, 0)
        
        refresh()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // Scrolls back to top so that top of list is loaded
        membersTable.contentOffset = CGPointMake(0, 0 - membersTable.contentInset.top)
    }
    
    func refreshIfVisible() {
        if isViewLoaded() && view.window != nil {
            refresh()
        }
    }
    
    func refresh() {
        println("refreshing PartyMembersViewController")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if UserManager.sharedUser.setup == true {
                if PartyManager.sharedParty.state != .None {
                    // Actually show members stuff
                    hideMessages()
                    hideMembersTable(false)
                    
                    membersManager.clearForUpdate()
                    membersManager.update(
                        completion: {
                            dispatchAsyncToMainQueue(action: {
                                self.membersTable.reloadData()
                                self.loadImagesForOnScreenRows()
                                self.tableViewController.refreshControl!.endRefreshing()
                            })
                        }
                    )
                } else {
                    showMessages("Not member of a party", detailLine: "Become a party member by joining or creating a party")
                    hideMembersTable(true)
                    tableViewController.refreshControl!.endRefreshing()
                }
            } else {
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
                hideMembersTable(true)
                tableViewController.refreshControl!.endRefreshing()
            }
        } else {
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
            hideMembersTable(true)
            tableViewController.refreshControl!.endRefreshing()
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
        let userCount = membersManager.users.count
        return membersManager.hasMorePages() ? (userCount + 1) : (userCount)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if membersManager.users.count > 0 {
            tableView.backgroundView = nil
        } else {
            // Display a message when the table is empty
            setTableBackgroundViewWithMessages(tableView, "No party members", "Please pull down to refresh, or invite some friends")
        }
        
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row < membersManager.users.count {
            return memberCellForRowAtIndexPath(indexPath, fromTableView: tableView)
        } else {
            return loadingCell()
        }
    }
    
    func loadingCell() -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, cell.bounds.size.width)
        cell.backgroundColor = UIColor.clearColor()
        let f = cell.frame
        cell.frame = CGRectMake(f.origin.x, f.origin.y, f.width, heightForRows)
        
        cell.tag = LoadingCellTag
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.center = cell.center
        cell.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        return cell
    }
    
    func memberCellForRowAtIndexPath(indexPath: NSIndexPath, fromTableView tableView: UITableView) -> PartyMemberCell {
        var membersCell = membersTable.dequeueReusableCellWithIdentifier(PartyMemberCellIdentifier, forIndexPath: indexPath) as PartyMemberCell
        
        let user = membersManager.users[indexPath.row]
        
        setUserInfoLabelsText(upvoteLabel: membersCell.userUpvoteLabel, numUpvotes: user.upvoteCount, songLabel: membersCell.userSongLabel, numSongs: user.songCount, hotnessLabel: membersCell.userHotnessLabel, percentHotness: user.hotnessPercent, userNameLabel: membersCell.userNameLabel, userName: user.name)
        
        membersCell.triangleView.color = user.colorToUIColor
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
        if membersManager.users.count > 0 {
            let visiblePaths = membersTable.indexPathsForVisibleRows() as [NSIndexPath]
            
            let numberOfValidRows = membersManager.users.count - 1 // "- 1" b/c index of rows start at 0
            
            for path in visiblePaths {
                // Have to check this b/c the last visible row can be the loadingCell, which is an invalid array index
                if path.row <= numberOfValidRows {
                    let user = membersManager.users[path.row]
                    
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
    }
}

extension PartyMembersViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return heightForRows
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Loading cell triggers loading the next page of info
        if cell.tag == LoadingCellTag {
            membersManager.update(
                completion: {
                    self.membersTable.reloadData()
                    self.loadImagesForOnScreenRows()
                    self.tableViewController.refreshControl!.endRefreshing()
                }
            )
        }
    }
}

extension PartyMembersViewController: UIScrollViewDelegate {
    // Load the images for all onscreen rows when scrolling is finished
    
    // Called on finger up if the user dragged. Decelerate is true if it will continue moving afterwards
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Load the images for the cells if it won't be moving afterwards
        if !decelerate {
            loadImagesForOnScreenRows()
        }
    }
    
    // Called when the scroll view grinds to a halt
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        loadImagesForOnScreenRows()
    }
}
