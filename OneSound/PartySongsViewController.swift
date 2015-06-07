//
//  PartySongsViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let PartySongsViewControllerNibName = "PartySongsViewController"
let PartySongCellIndentifier = "PartySongCell"
let LoadingCellTag = 1

class PartySongsViewController: OSViewController {

    let songCellImagePlaceholder = UIImage(named: "songCellImagePlaceholder")
    let songTableViewImageCache = (UIApplication.sharedApplication().delegate as! AppDelegate).songTableViewImageCache
    let playlistManager = PartyManager.sharedParty.playlistManager
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    
    @IBOutlet weak var songsTable: UITableView!
    
    var addSongButton: UIBarButtonItem!
    
    var tableViewController: UITableViewController!
    
    let heightForRows: CGFloat = 64.0
    
    func addSong() {
        let addSongViewController = AddSongViewController(nibName: AddSongViewControllerNibName, bundle: nil)
        let navC = UINavigationController(rootViewController: addSongViewController)
        presentViewController(navC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        osvcVariables.screenName = PartySongsViewControllerNibName
        
        addSongButton = UIBarButtonItem(title: "Add", style: UIBarButtonItemStyle.Plain, target: self, action: "addSong")
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshIfVisible", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and UserManager is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshIfVisible", name: UserManagerInformationDidChangeNotification, object: nil)
        // Should update when a party song is added
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: PartySongWasAddedNotification, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableData", name: PartyManagerSongInformationDidChangeNotification, object: nil)
        
        // Creating an (empty) footer stops table from showing empty cells
        songsTable.tableFooterView = UIView(frame: CGRectZero)
        
        let nib = UINib(nibName: PartySongCellNibName, bundle: nil)
        songsTable.registerNib(nib, forCellReuseIdentifier: PartySongCellIndentifier)
        
        // Setup the refresh control
        // Added and placed inside a UITableViewController to remove "stutter" from having a
        // UIViewController handle the refresh control
        // http://stackoverflow.com/questions/12497940/uirefreshcontrol-without-uitableviewcontroller
        tableViewController = UITableViewController(style: UITableViewStyle.Plain)
        tableViewController.tableView = songsTable
        addChildViewController(tableViewController)
        tableViewController.refreshControl = UIRefreshControl()
        tableViewController.refreshControl!.backgroundColor = UIColor.blue()
        tableViewController.refreshControl!.tintColor = UIColor.white()
        tableViewController.refreshControl!.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        hideMessages()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        parentViewController!.navigationItem.title = "Playlist"
        
        // Allows cells to flow under nav bar and tab bar, but not stop scrolling behind them when content stops
        songsTable.contentInset = UIEdgeInsetsMake(65, 0, 49, 0)
        
        // Fixes table having different margins in iOS 8
        if songsTable.respondsToSelector("setLayoutMargins:") {
            songsTable.layoutMargins = UIEdgeInsetsZero
        }
        
        refresh()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // Scrolls back to top so that top of playlist is loaded
        songsTable.contentOffset = CGPointMake(0, 0 - songsTable.contentInset.top)
    }
    
    func refreshIfVisible() {
        if isViewLoaded() && view.window != nil {
            refresh()
        }
    }
    
    override func refresh() {
        super.refresh()
        // println("refreshing PartySongViewController")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if UserManager.sharedUser.setup == true {
                if PartyManager.sharedParty.state != .None {
                    // Actually show songs stuff
                    addSongButton.enabled = true
                    hideMessages()
                    hideSongsTable(false)
                    
                    playlistManager.clearForUpdate()
                    playlistManager.update(
                        completion: {
                            dispatchAsyncToMainQueue(action: {
                                self.reloadDataAndImagesForOnScreenRows()
                                self.tableViewController.refreshControl!.endRefreshing()
                            })
                        }
                    )
                } else {
                    showMessages("Not member of a party", detailLine: "Become a party member by joining or creating a party")
                    addSongButton.enabled = false
                    hideSongsTable(true)
                    tableViewController.refreshControl!.endRefreshing()
                }
            } else {
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
                addSongButton.enabled = false
                hideSongsTable(true)
                tableViewController.refreshControl!.endRefreshing()
            }
        } else {
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
            addSongButton.enabled = false
            hideSongsTable(true)
            tableViewController.refreshControl!.endRefreshing()
        }
    }
    
    func hideSongsTable(hidden: Bool) {
        songsTable.hidden = hidden
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
    
    func reloadDataAndImagesForOnScreenRows() {
        songsTable.reloadData()
        loadImagesForOnScreenRows()
    }
    
    func shouldAllowActionsOnSongs() -> Bool {
        return !playlistManager.updating
    }
}

extension PartySongsViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let songCount = playlistManager.songs.count
        return playlistManager.hasMorePages() ? (songCount + 1) : (songCount)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if playlistManager.songs.count > 0 {
            tableView.backgroundView = nil
        } else {
            // Display a message when the table is empty
            setTableBackgroundViewWithMessages(tableView, "No songs are queued in the playlist", "Please pull down to refresh, or add a song")
        }
        
        return 1
    }
    
    // Should a cell be able to be deleted?
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Remove delete button from normal table (use SWTableViewCell instead)
        return false
    }
    
    // Delete the cell
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // If deleting the cell
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let songsToDelete = playlistManager.songs.count > 0
            let cellIsLoadingCell = indexPath.row == playlistManager.songs.count // 1 past # of songs will be loading cell
            
            if songsToDelete && !cellIsLoadingCell && shouldAllowActionsOnSongs()
                || PartyManager.sharedParty.state == .Host
                || PartyManager.sharedParty.state == .HostStreamable {
                    
                // Delete this cell's song
                playlistManager.deleteSongAtIndex(indexPath.row,
                    completion: {
                        dispatchAsyncToMainQueue(action: {
                            tableView.beginUpdates()
                            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                            tableView.endUpdates()
                        })
                    }
                )
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        if indexPath.row < playlistManager.songs.count {
            cell = songCellForRowAtIndexPath(indexPath, fromTableView: tableView)
        } else {
            cell = loadingCell()
        }
        
        if cell.respondsToSelector("preservesSuperviewLayoutMargins:") {
            cell.preservesSuperviewLayoutMargins = false
        }
        
        return cell
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
    
    func songCellForRowAtIndexPath(indexPath: NSIndexPath, fromTableView tableView: UITableView) -> PartySongCell {
        var songCell = songsTable.dequeueReusableCellWithIdentifier(PartySongCellIndentifier, forIndexPath: indexPath) as! PartySongCell
        
        // "Connect" the cell to the table to receive song votes
        songCell.index = indexPath.row
        songCell.voteDelegate = self
        
        // Set up SW Table Cell
        songCell.delegate = self
        songCell.rightUtilityButtons = rightUtilityButtonsForCellAtIndexPath(indexPath)
        
        
        var song = playlistManager.songs[indexPath.row]
        
        songCell.songImage.image = songCellImagePlaceholder
        if song.name != nil { songCell.songName.text = song.name! }
        if song.artistName != nil { songCell.songArtist.text = song.artistName! }
        if song.voteCount != nil { songCell.setVoteCount(song.voteCount!) }
        
        songCell.resetThumbsUpDownButtons()
        if song.userVote != nil {
            switch song.userVote! {
            case .Up:
                songCell.setThumbsUpSelected()
            case .Down:
                songCell.setThumbsDownSelected()
            default:
                songCell.resetThumbsUpDownButtons()
            }
        }
        
        
        if song.artworkURL != nil {
            if tableView.dragging == false && tableView.decelerating == false {
                let largerArtworkURL = song.artworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                
                songTableViewImageCache.queryDiskCacheForKey(largerArtworkURL,
                    done: { image, imageCacheType in
                        if image != nil {
                            let updateCell = self.songsTable.cellForRowAtIndexPath(indexPath) as? PartySongCell
                            
                            if updateCell != nil {
                                // If the cell for that row is still visible and correct
                                updateCell!.songImage.image = image
                            }
                        } else {
                            self.startImageDownload(largerArtworkURL, forIndexPath: indexPath)
                        }
                    }
                )
            }
        } else {
            songCell.songImage.image = songCellImagePlaceholder
        }
        
        return songCell
    }
    
    private func rightUtilityButtonsForCellAtIndexPath(indexPath: NSIndexPath) -> [AnyObject] {
        var rightUtilityButtons = NSMutableArray()
        
        // If the user is a guest, don't allow them to favorite songs
        if showsFavoriteForSongCellAtIndexPathWithRow(indexPath.row) {
            let song = playlistManager.songs[indexPath.row]
            
            var favoriteButtonColor: UIColor
            if song.isFavorited != nil && song.isFavorited! {
                favoriteButtonColor = UIColor.yellow()
            } else {
                favoriteButtonColor = UIColor.yellow().colorWithAlphaComponent(0.3)
            }
            
            rightUtilityButtons.sw_addUtilityButtonWithColor(favoriteButtonColor, icon: UIImage(named: "favoriteIcon"))
        }
        
        // Check if the current song has been added by the user or if the user is host
        if showsDeleteForSongCellAtIndexPathWithRow(indexPath.row) {
            rightUtilityButtons.sw_addUtilityButtonWithColor(UIColor.red(), icon: UIImage(named: "trashIcon"))
        }
        
        return rightUtilityButtons as [AnyObject]
    }
    
    func showsDeleteForSongCellAtIndexPathWithRow(row: Int) -> Bool {
        let songsToDelete = playlistManager.songs.count > 0
        let cellIsLoadingCell = row == playlistManager.songs.count // 1 past # of songs will be loading cell
        
        
        if songsToDelete && !cellIsLoadingCell && shouldAllowActionsOnSongs() {
            // If this is the user's song, they can choose to delete it
            if playlistManager.songs[row].userID == UserManager.sharedUser.id
                || PartyManager.sharedParty.state == .Host
                || PartyManager.sharedParty.state == .HostStreamable {
                    return true
            }
        }
        
        return false
    }
    
    func showsFavoriteForSongCellAtIndexPathWithRow(row: Int) -> Bool {
        return !UserManager.sharedUser.guest
    }
    
    func startImageDownload(urlString: String, forIndexPath indexPath: NSIndexPath) {
        
        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: urlString), options: nil, progress: nil,
            completed: { image, error, cacheType, boolValue, url in
                // Make sure it's still the correct cell
                let updateCell = self.songsTable.cellForRowAtIndexPath(indexPath) as? PartySongCell
                
                if updateCell != nil {
                    // If the cell for that row is still visible and correct
                    
                    if error == nil && image != nil {
                        // From when using the image as background for the full cell
                        //let processedImage = cropImageCenterFromSideEdgesWhilePreservingAspectRatio(withWidth: 640, withHeight: self.heightForRows * 2.0, image: image)
                        
                        dispatchAsyncToMainQueue(action: {
                            updateCell!.songImage.image = image
                            updateCell!.songImage.setNeedsLayout()
                        })
                        //updateCell!.songImage.setNeedsLayout()
                        
                        self.songTableViewImageCache.storeImage(image, forKey: urlString)
                        
                    } else {
                        dispatchAsyncToMainQueue(action: {
                            updateCell!.songImage.image = self.songCellImagePlaceholder
                            updateCell!.songImage.setNeedsLayout()
                        })
                    }
                }
            }
        )
    }
    
    func loadImagesForOnScreenRows() {
        if playlistManager.songs.count > 0 {
            let visiblePaths = songsTable.indexPathsForVisibleRows() as! [NSIndexPath]
            
            let numberOfValidRows = playlistManager.songs.count - 1 // "- 1" b/c index of rows start at 0
            
            for path in visiblePaths {
                // Have to check this b/c the last visible row can be the loadingCell, which is an invalid array index
                if path.row <= numberOfValidRows {
                    let song = playlistManager.songs[path.row]
                    
                    if song.artworkURL != nil {
                        // From when using the image as background for the full cell
                        //let largerArtworkURL = song.artworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                        let artworkURL = song.artworkURL!
                        
                        songTableViewImageCache.queryDiskCacheForKey(artworkURL,
                            done: { image, imageCacheType in
                                if image != nil {
                                    let updateCell = self.songsTable.cellForRowAtIndexPath(path) as? PartySongCell
                                    
                                    if updateCell != nil {
                                        // If the cell for that row is still visible and correct
                                        updateCell!.songImage.image = image
                                        updateCell!.songImage.setNeedsLayout()
                                    }
                                } else {
                                    self.startImageDownload(artworkURL, forIndexPath: path)
                                }
                            }
                        )
                    } else {
                        let updateCell = self.songsTable.cellForRowAtIndexPath(path) as? PartySongCell
                        
                        if updateCell != nil {
                            // If the cell for that row is still visible and correct
                            updateCell!.songImage.image = songCellImagePlaceholder
                        }
                    }
                }
            }
        }
    }
}

extension PartySongsViewController: UITableViewDelegate {
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return heightForRows
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Loading cell triggers loading the next page of info
        if cell.tag == LoadingCellTag {
            playlistManager.update(
                completion: {
                    self.reloadDataAndImagesForOnScreenRows()
                    self.tableViewController.refreshControl!.endRefreshing()
                }
            )
        }
    }
}

extension PartySongsViewController: UIScrollViewDelegate {
    // MARK: UIScrollViewDelegate
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

extension PartySongsViewController: PartySongCellDelegate {
    // MARK: PartySongCellDelegate
    
    // Handle votes on songs
    func didVoteOnSongCellAtIndex(index: Int, withVote vote: PartySongVote, andVoteCountChange voteCountChange: Int) {
        let song = playlistManager.songs[index]
        
        if shouldAllowActionsOnSongs() {
            if let songID = song.songID {
                switch vote {
                case .Up:
                    PartyManager.sharedParty.songUpvote(songID)
                case .Down:
                    PartyManager.sharedParty.songDownvote(songID)
                case .Clear:
                    PartyManager.sharedParty.songClearVote(songID)
                }
                
                // Reorder the song based on the vote
                let newIndex = playlistManager.moveSongAtIndex(index, afterChangingVoteCountBy: voteCountChange, withVote: vote)
                
                // The song has changed locations, so update for and animate the change
                if newIndex != index {
                    songsTable.reloadData()
                    
                    songsTable.beginUpdates()
                    songsTable.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Left)
                    songsTable.insertRowsAtIndexPaths([NSIndexPath(forRow: newIndex, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Left)
                    songsTable.endUpdates()
                    
                    loadImagesForOnScreenRows()
                }
            }
        }
    }
}

extension PartySongsViewController: SWTableViewCellDelegate {
    // MARK: SWTableViewCellDelegate
    
    // Handle button presses
    
    // click event on right utility button
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex rightButtonsIndex: NSInteger) {
        
        //
        // Ensure correct cell type and indexPath exist
        //
        
        let songCell: PartySongCell! = cell as? PartySongCell
        if songCell == nil { return }
        
        let cellIndexPath = songsTable.indexPathForCell(cell)
        if cellIndexPath == nil { return }
        var row = cellIndexPath!.row
        
        
        //
        // Determine which button was pressed
        //
        
        var isDeleteButton = false
        var isFavoriteButton = false
        
        if showsDeleteForSongCellAtIndexPathWithRow(row) && showsFavoriteForSongCellAtIndexPathWithRow(row) {
            isDeleteButton = rightButtonsIndex == 1
            isFavoriteButton = rightButtonsIndex == 0
        } else if showsDeleteForSongCellAtIndexPathWithRow(row) {
            isDeleteButton = true
        } else {
            isFavoriteButton = true
        }
        
        
        //
        // Actions based on the button pressed
        //
        
        if isFavoriteButton {
            // Favorite button pressed
            if let songCell = cell as? PartySongCell {
                let song = playlistManager.songs[row]
                let songWasFavorited = song.isFavorited != nil && song.isFavorited!
                
                // Flip the isFavorited bool of the local song model
                song.isFavorited = !songWasFavorited
                
                if songWasFavorited {
                    // Un-favorite the song
                    // TODO: api call to unfavorite the song
                } else {
                    // Favorite the song
                    PartyManager.sharedParty.songFavorite(song.songID!)
                }
                
                // Reload the song cells buttons to be correct
                songCell.rightUtilityButtons = rightUtilityButtonsForCellAtIndexPath(cellIndexPath!)
            }
        } else if isDeleteButton {
            // Delete
            if let songCell = cell as? PartySongCell {
                if let row = songCell.index {
                    tableView(songsTable, commitEditingStyle: UITableViewCellEditingStyle.Delete, forRowAtIndexPath: NSIndexPath(forRow: row, inSection: 0))
                }
            }
        }
        
        
        //
        // Do this regardless of which button it was
        //
        
        cell.hideUtilityButtonsAnimated(true)
    }
    
    
    
    // prevent multiple cells from showing utilty buttons simultaneously
    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell) -> Bool {
        return true
    }
}