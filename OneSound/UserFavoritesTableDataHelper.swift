//
//  UserFavoritesTableDataHelper.swift
//  OneSound
//
//  Created by adam on 6/6/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation

let UserFavoriteSongCellIdentifier = "UserFavoriteSongCell"

// Protocol for a view controller that controls the UserFavoritesTableDataHelper
// Keeps the UserFavoritesTableDataHelper flexibility
@objc protocol UserFavoritesTableDataHelperDelegate: class
{
    func rightUtilityButtonsForCellAtIndexPath(indexPath: NSIndexPath) -> [AnyObject]
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex rightButtonsIndex: NSInteger)
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    
    // The lines of text that show when the table is empty
    func titleMessageForEmptyTableBackgroundView() -> String
    func detailMessageForEmptyTableBackgroundView() -> String
    
    optional func refreshControlBackgroundColor() -> UIColor
    optional func refreshControlTintColor() -> UIColor
}

// Manages displaying a users favorites in a table view
class UserFavoritesTableDataHelper: OSTableViewController
{
    let userFavoritesManager = UserFavoritesManager()
    let songCellImagePlaceholder = UIImage(named: "songCellImagePlaceholder")
    let songTableViewImageCache = (UIApplication.sharedApplication().delegate as! AppDelegate).songTableViewImageCache
    let HeightForRows: CGFloat = 64.0
    
    weak var delegate: UserFavoritesTableDataHelperDelegate?
    
    private var titleMessageForEmptyTableBackgroundView = ""
    private var detailMessageForEmptyTableBackgroundView = ""
    
    override func viewDidLoad()
    {
        // Creating an (empty) footer stops table from showing empty cells
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        if delegate != nil
        {
            titleMessageForEmptyTableBackgroundView = delegate!.titleMessageForEmptyTableBackgroundView()
            detailMessageForEmptyTableBackgroundView = delegate!.detailMessageForEmptyTableBackgroundView()
            
            if delegate!.refreshControlBackgroundColor?() != nil && delegate!.refreshControlTintColor?() != nil
            {
                refreshControl = UIRefreshControl()
                refreshControl!.backgroundColor = delegate!.refreshControlBackgroundColor!()
                refreshControl!.tintColor = delegate!.refreshControlTintColor!()
                refreshControl!.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
                
            }
        }
        
        let nib = UINib(nibName: UserFavoriteSongCellNibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: UserFavoriteSongCellIdentifier)
        
        // Fixes table having different margins in iOS 8
        if tableView.respondsToSelector("setLayoutMargins:")
        {
            tableView.layoutMargins = UIEdgeInsetsZero
        }
        
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        // Fixes table having different margins in iOS 8
        if tableView.respondsToSelector("setLayoutMargins:")
        {
            tableView.layoutMargins = UIEdgeInsetsZero
        }
        
        refresh()
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        // Scrolls back to top so that top of list is loaded
        tableView.contentOffset = CGPointMake(0, 0 - tableView.contentInset.top)
    }
    
    func refreshIfVisible()
    {
        if isViewLoaded() && view.window != nil
        {
            refresh()
        }
    }
    
    override func refresh()
    {
        if AFNetworkReachabilityManager.sharedManager().reachable && UserManager.sharedUser.setup
        {
            userFavoritesManager.pagedDataArray.clearForUpdate()
            userFavoritesManager.pagedDataArray.fetchNextPage(
                completion:
                {
                    self.reloadDataAndImagesForOnScreenRows()
                    self.refreshControl?.endRefreshing()
                }
            )
        } else
        {
            refreshControl?.endRefreshing()
        }
    }
    
    func reloadDataAndImagesForOnScreenRows()
    {
        tableView.reloadData()
        loadImagesForOnScreenRows()
    }
    
    func shouldAllowActionsOnSongs() -> Bool
    {
        return !userFavoritesManager.pagedDataArray.updating
    }
}

extension UserFavoritesTableDataHelper: UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let favoriteCount = userFavoritesManager.pagedDataArray.data.count
        return userFavoritesManager.pagedDataArray.hasMorePages() ? (favoriteCount + 1) : (favoriteCount)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if userFavoritesManager.pagedDataArray.data.count > 0 {
            tableView.backgroundView = nil
        } else {
            // Display a message when the table is empty
            setTableBackgroundViewWithMessages(tableView, titleMessageForEmptyTableBackgroundView, detailMessageForEmptyTableBackgroundView)
        }
        
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell: UITableViewCell
        
        if indexPath.row < userFavoritesManager.pagedDataArray.data.count {
            cell = songCellForRowAtIndexPath(indexPath, fromTableView: tableView)
        } else {
            cell = loadingCell()
        }
        
        if cell.respondsToSelector("preservesSuperviewLayoutMargins:") {
            cell.preservesSuperviewLayoutMargins = false
        }
        
        return cell
    }
    
    func loadingCell() -> UITableViewCell
    {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, cell.bounds.size.width)
        cell.backgroundColor = UIColor.clearColor()
        let f = cell.frame
        cell.frame = CGRectMake(f.origin.x, f.origin.y, f.width, HeightForRows)
        
        cell.tag = LoadingCellTag
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.center = cell.center
        cell.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        return cell
    }
    
    func songCellForRowAtIndexPath(indexPath: NSIndexPath, fromTableView tableView: UITableView) -> UserFavoriteSongCell
    {
        var songCell = tableView.dequeueReusableCellWithIdentifier(UserFavoriteSongCellIdentifier, forIndexPath: indexPath) as! UserFavoriteSongCell
        
        songCell.delegate = self
        songCell.rightUtilityButtons = delegate?.rightUtilityButtonsForCellAtIndexPath(indexPath)
        
        var song = userFavoritesManager.pagedDataArray.data[indexPath.row]
        
        songCell.songImage.image = songCellImagePlaceholder
        if song.name != nil { songCell.songName.text = song.name! }
        if song.artistName != nil { songCell.songArtist.text = song.artistName! }
        
        if song.artworkURL != nil
        {
            if tableView.dragging == false && tableView.decelerating == false
            {
                let largerArtworkURL = song.artworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                
                songTableViewImageCache.queryDiskCacheForKey(largerArtworkURL,
                    done: { image, imageCacheType in
                        if image != nil
                        {
                            let updateCell = self.tableView.cellForRowAtIndexPath(indexPath) as? UserFavoriteSongCell
                            
                            if updateCell != nil
                            {
                                // If the cell for that row is still visible and correct
                                updateCell!.songImage.image = image
                            }
                        } else
                        {
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
    
    func startImageDownload(urlString: String, forIndexPath indexPath: NSIndexPath)
    {
        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: urlString), options: nil, progress: nil,
            completed: { image, error, cacheType, boolValue, url in
                // Make sure it's still the correct cell
                let updateCell = self.tableView.cellForRowAtIndexPath(indexPath) as? UserFavoriteSongCell
                
                if updateCell != nil
                {
                    // If the cell for that row is still visible and correct
                    
                    if error == nil && image != nil
                    {
                        // From when using the image as background for the full cell
                        //let processedImage = cropImageCenterFromSideEdgesWhilePreservingAspectRatio(withWidth: 640, withHeight: self.heightForRows * 2.0, image: image)
                        
                        dispatchAsyncToMainQueue(action:{
                            updateCell!.songImage.image = image
                            updateCell!.songImage.setNeedsLayout()
                        })
                        //updateCell!.songImage.setNeedsLayout()
                        
                        self.songTableViewImageCache.storeImage(image, forKey: urlString)
                        
                    } else
                    {
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
        if userFavoritesManager.pagedDataArray.data.count > 0 {
            let visiblePaths = tableView.indexPathsForVisibleRows() as! [NSIndexPath]
            
            let numberOfValidRows = userFavoritesManager.pagedDataArray.data.count - 1 // "- 1" b/c index of rows start at 0
            
            for path in visiblePaths
            {
                // Have to check this b/c the last visible row can be the loadingCell, which is an invalid array index
                if path.row <= numberOfValidRows
                {
                    let song = userFavoritesManager.pagedDataArray.data[path.row]
                    
                    if song.artworkURL != nil
                    {
                        // From when using the image as background for the full cell
                        //let largerArtworkURL = song.artworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                        let artworkURL = song.artworkURL!
                        
                        songTableViewImageCache.queryDiskCacheForKey(artworkURL,
                            done: { image, imageCacheType in
                                if image != nil
                                {
                                    let updateCell = self.tableView.cellForRowAtIndexPath(path) as? UserFavoriteSongCell
                                    if updateCell != nil {
                                        // If the cell for that row is still visible and correct
                                        updateCell!.songImage.image = image
                                        updateCell!.songImage.setNeedsLayout()
                                    }
                                } else
                                {
                                    self.startImageDownload(artworkURL, forIndexPath: path)
                                }
                            }
                        )
                    } else
                    {
                        let updateCell = self.tableView.cellForRowAtIndexPath(path) as? UserFavoriteSongCell
                        if updateCell != nil
                        {
                            // If the cell for that row is still visible and correct
                            updateCell!.songImage.image = songCellImagePlaceholder
                        }
                    }
                }
            }
        }
    }
}

extension UserFavoritesTableDataHelper: UITableViewDelegate {
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return HeightForRows
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Loading cell triggers loading the next page of info
        if cell.tag == LoadingCellTag
        {
            userFavoritesManager.pagedDataArray.fetchNextPage(
                completion: {
                    self.reloadDataAndImagesForOnScreenRows()
                    self.refreshControl?.endRefreshing()
                }
            )
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (delegate != nil) ? delegate!.tableView(tableView, heightForHeaderInSection: section) : 0.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return (delegate != nil) ? delegate!.tableView(tableView, viewForHeaderInSection: section) : nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if delegate != nil {
            delegate!.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
    }
}

extension UserFavoritesTableDataHelper: UIScrollViewDelegate {
    // MARK: UIScrollViewDelegate
    // Load the images for all onscreen rows when scrolling is finished
    
    // Called on finger up if the user dragged. Decelerate is true if it will continue moving afterwards
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Load the images for the cells if it won't be moving afterwards
        if !decelerate {
            loadImagesForOnScreenRows()
        }
    }
    
    // Called when the scroll view grinds to a halt
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        loadImagesForOnScreenRows()
    }
}

extension UserFavoritesTableDataHelper: SWTableViewCellDelegate
{
    // MARK: SWTableViewCellDelegate
    
    // Click event on right utility button
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex rightButtonsIndex: NSInteger)
    {
        delegate?.swipeableTableViewCell(cell, didTriggerRightUtilityButtonWithIndex: rightButtonsIndex)

    }
    
    // Prevent multiple cells from showing utilty buttons simultaneously
    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell) -> Bool
    {
        return true
    }
}