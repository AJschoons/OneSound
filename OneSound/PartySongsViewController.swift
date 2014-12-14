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

class PartySongsViewController: UIViewController {

    let songCellImagePlaceholder = UIImage(named: "songCellImagePlaceholder")
    
    let songTableViewImageCache = (UIApplication.sharedApplication().delegate as AppDelegate).songTableViewImageCache
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    
    @IBOutlet weak var songsTable: UITableView!
    
    var addSongButton: UIBarButtonItem!
    
    let heightForRows: CGFloat = 64.0
    
    func addSong() {
        let addSongViewController = AddSongViewController(nibName: AddSongViewControllerNibName, bundle: nil)
        let navC = UINavigationController(rootViewController: addSongViewController)
        presentViewController(navC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        addSongButton = UIBarButtonItem(title: "Add", style: UIBarButtonItemStyle.Plain, target: self, action: "addSong")
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        // Should update when a party song is added
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: PartySongWasAddedNotification, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableData", name: LocalPartySongInformationDidChangeNotification, object: nil)
        
        // Creating an (empty) footer stops table from showing empty cells
        songsTable.tableFooterView = UIView(frame: CGRectZero)
        
        let nib = UINib(nibName: PartySongCellNibName, bundle: nil)
        songsTable.registerNib(nib, forCellReuseIdentifier: PartySongCellIndentifier)
        
        hideMessages()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.visibleViewController.title = "Playlist"
        refresh()
    }
    
    func refreshAfterDelay() {
        println("should be refreshing after delay")
        NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "refresh", userInfo: nil, repeats: false)
    }
    
    func reloadTableData() {
        songsTable.reloadData()
    }
    
    // Copy pasta'd from Profile view controller to have the same kind of refresh logic
    // Keeping the commented out things for now to show what kind of changes were made for that
    // TODO: update the refresh to remove comments irrelevant to this controller when finished w/ it
    func refresh() {
        println("refreshing PartySongViewController")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                if LocalUser.sharedUser.party != nil {
                    if LocalParty.sharedParty.setup == true {
                        // Actually show songs stuff
                        hideMessages()
                        hideSongsTable(false)
                        LocalParty.sharedParty.updatePartySongs(LocalParty.sharedParty.partyID!, completion: {
                            dispatchAsyncToMainQueue(action: {
                                self.songsTable.reloadData()
                                self.loadImagesForOnScreenRows()
                            })
                        })
                    } else {
                        showMessages("Well, this is awkward", detailLine: "We're not really sure what happened, try refreshing the party!")
                        hideSongsTable(true)
                    }
                } else {
                    showMessages("Not member of a party", detailLine: "Become a party member by joining or creating a party")
                    hideSongsTable(true)
                }
            } else {
                //setUserInfoHidden(true)
                //setStoriesTableToHidden(true)
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
                hideSongsTable(true)
                //disableButtons()
            }
        } else {
            //setUserInfoHidden(true)
            //setStoriesTableToHidden(true)
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
            hideSongsTable(true)
            //disableButtons()
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
}

extension PartySongsViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocalParty.sharedParty.songs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var songCell = songsTable.dequeueReusableCellWithIdentifier(PartySongCellIndentifier, forIndexPath: indexPath) as PartySongCell
        
        if indexPath.row <= LocalParty.sharedParty.songs.count {
            var song = LocalParty.sharedParty.songs[indexPath.row]
            
            songCell.songID = song.songID
            
            songCell.songImage.image = songCellImagePlaceholder
            
            if song.name != nil {
                songCell.songName.text = song.name!
                
                // Make the label text be left-aligned if the text is too big
                let stringSize = (song.name! as NSString).sizeWithAttributes([NSFontAttributeName: songCell.songName.font])
                if (stringSize.width + 1) > songCell.songName.frame.width {
                    songCell.songName.textAlignment = NSTextAlignment.Left
                } else {
                    songCell.songName.textAlignment = NSTextAlignment.Center
                }
            }
            
            if song.artistName != nil {
                songCell.songArtist.text = song.artistName!
                
                // Make the label text be left-aligned if the text is too big
                let stringSize = (song.artistName! as NSString).sizeWithAttributes([NSFontAttributeName: songCell.songArtist.font])
                if (stringSize.width + 1) > songCell.songArtist.frame.width {
                    songCell.songArtist.textAlignment = NSTextAlignment.Left
                } else {
                    songCell.songArtist.textAlignment = NSTextAlignment.Center
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
        }
        
        return songCell
    }
    
    func startImageDownload(urlString: String, forIndexPath indexPath: NSIndexPath) {
        
        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: urlString), options: nil, progress: nil,
            completed: { image, error, cacheType, boolValue, url in
                // Make sure it's still the correct cell
                let updateCell = self.songsTable.cellForRowAtIndexPath(indexPath) as? PartySongCell
                
                if updateCell != nil {
                    // If the cell for that row is still visible and correct
                    
                    if error == nil && image != nil {
                        let processedImage = cropImageCenterFromSideEdgesWhilePreservingAspectRatio(withWidth: 640, withHeight: self.heightForRows * 2.0, image: image)
                        
                        self.songTableViewImageCache.storeImage(processedImage, forKey: urlString)
                        
                        dispatchAsyncToMainQueue(action: {
                            updateCell!.songImage.image = processedImage
                            updateCell!.songImage.setNeedsLayout()
                        })
                        //updateCell!.songImage.setNeedsLayout()
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
        let visiblePaths = songsTable.indexPathsForVisibleRows() as [NSIndexPath]
        
        for path in visiblePaths {
            let song = LocalParty.sharedParty.songs[path.row]
            
            if song.artworkURL != nil {
                let largerArtworkURL = song.artworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                
                songTableViewImageCache.queryDiskCacheForKey(largerArtworkURL,
                    done: { image, imageCacheType in
                        if image != nil {
                            let updateCell = self.songsTable.cellForRowAtIndexPath(path) as? PartySongCell
                            
                            if updateCell != nil {
                                // If the cell for that row is still visible and correct
                                updateCell!.songImage.image = image
                                updateCell!.songImage.setNeedsLayout()
                            }
                        } else {
                            self.startImageDownload(largerArtworkURL, forIndexPath: path)
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

extension PartySongsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return heightForRows
    }
}

extension PartySongsViewController: UIScrollViewDelegate {
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