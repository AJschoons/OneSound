//
//  AddSongViewController.swift
//  OneSound
//
//  Created by adam on 8/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit
import QuartzCore

let AddSongViewControllerNibName = "AddSongViewController"
let SongSearchResultCellIdentifier = "SongSearchResultCell"
let PartySongWasAddedNotification = "PartySongWasAdded"

let SongDurationMaxInSeconds = 600 // 10 minute max

class AddSongViewController: OSModalViewController {

    @IBOutlet weak var songSearchBar: UISearchBar!
    @IBOutlet weak var favoritesTable: UITableView!
    @IBOutlet weak var searchResultsTable: UITableView!
    @IBOutlet weak var animatedOneSoundOne: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var searchTypeControl: UISegmentedControl!
    var searchResultsArray = [SongSearchResult]()
    
    let heightForRows: CGFloat = 68.0
    let songSearchBarPlaceholderText = "Enter a song name"
    let TypingSearchThreshold = 3
    
    var firstTypingSearch = true
    var songSearchTimer: NSTimer = NSTimer()
    private let typingSearchServicePeriod: Double = 0.3 // Period in seconds of how often to update state. Play around with it
    var searchLength = 0
    
    private var searchBySoundcloud = true // Defaults to searching by soundcloud
    var noSearchResults = false
    private let addSongFavoritesTableViewController = AddSongFavoritesTableViewController()
    
    func search(searchTextLength: Int = 0, isSearchButtonPressed: Bool) {
        // Hide the keyboard
        //songSearchBar.resignFirstResponder()
        
        // Empty the table, reload to show its empty, start the animation
        noSearchResults = false // Decides if the table will show song rows, or a "no songs found" message
        searchResultsArray = []
        searchResultsTable.reloadData()
        loadingAnimationShouldBeAnimating(true)
        
        SCClient.sharedClient.searchSoundCloudForSongWithString(songSearchBar.text,
            success: {data, responseObject in
                let responseJSON = JSON(responseObject)
                //println(responseJSON)
                let songsArray = responseJSON.array
                //println(songsArray!)
                //println(songsArray!.count)
                
                var newSongSearchResults = [SongSearchResult]()
                
                if songsArray != nil {
                    for result in songsArray! {
                        //println(result)
                        let source = "sc"
                        let id = result["id"].int
                        let name = result["title"].string
                        let artistName = result["user"]["username"].string
                        var duration = result["duration"].int
                        let artworkURL = result["artwork_url"].string
                        let playbacks = result["playback_count"].int
                        
                        let streamable = result["streamable"].bool
                        
                        if duration != nil && streamable == true {
                            // Soundcloud duration is returned in milliseconds; convert to seconds
                            duration! /= 1000
                            if duration < SongDurationMaxInSeconds {
                                newSongSearchResults.append(SongSearchResult(source: source, externalID: id!, name: name!, artistName: artistName!, duration: duration!, artworkURL: artworkURL, numberOfPlaybacks: playbacks))
                            }
                        }
                    }
                }
                
                // This bool decides whether the table will show song rows, or a "no songs found" message
                self.noSearchResults = (newSongSearchResults.count == 0)
                
                self.searchResultsArray = newSongSearchResults
                self.searchResultsTable.reloadData()
                self.loadingAnimationShouldBeAnimating(false)
            },
            failure: { task, error in
                self.loadingAnimationShouldBeAnimating(false)
                defaultAFHTTPFailureBlock!(task: task, error: error)
            }
        )
    }

    func search() {//searchTextLength: Int = 0, isSearchButtonPressed: Bool) {
        // Hide the keyboard
        //songSearchBar.resignFirstResponder()
        if searchLength > 0 {
        
        if firstTypingSearch {
            // Empty the table, reload to show its empty, start the animation
            firstTypingSearch = false
            noSearchResults = false // Decides if the table will show party rows, or a "no parties found" message
            searchResultsArray = []
            searchResultsTable.reloadData()
            loadingAnimationShouldBeAnimating(true)
        }else {
            loadingAnimationShouldBeAnimating(false)
        }
        
        SCClient.sharedClient.searchSoundCloudForSongWithString(songSearchBar.text,
            success: {data, responseObject in
                let responseJSON = JSON(responseObject)
                //println(responseJSON)
                let songsArray = responseJSON.array
                //println(songsArray!)
                //println(songsArray!.count)
                
                var newSongSearchResults = [SongSearchResult]()
                
                if songsArray != nil {
                    for result in songsArray! {
                        //println(result)
                        let source = "sc"
                        let id = result["id"].int
                        let name = result["title"].string
                        let artistName = result["user"]["username"].string
                        var duration = result["duration"].int
                        let artworkURL = result["artwork_url"].string
                        let playbacks = result["playback_count"].int
                        
                        let streamable = result["streamable"].bool
                        
                        if duration != nil && streamable == true {
                            // Soundcloud duration is returned in milliseconds; convert to seconds
                            duration! /= 1000
                            if duration < SongDurationMaxInSeconds {
                                newSongSearchResults.append(SongSearchResult(source: source, externalID: id!, name: name!, artistName: artistName!, duration: duration!, artworkURL: artworkURL, numberOfPlaybacks: playbacks))
                            }
                        }
                    }
                }
                
                // This bool decides whether the table will show song rows, or a "no songs found" message
                self.noSearchResults = (newSongSearchResults.count == 0)
                
                self.searchResultsArray = newSongSearchResults
                self.searchResultsTable.reloadData()
                self.loadingAnimationShouldBeAnimating(false)
            },
            failure: { task, error in
                self.loadingAnimationShouldBeAnimating(false)
                defaultAFHTTPFailureBlock!(task: task, error: error)
            }
        )
        }
    }

    
    func cancel() {
        view.endEditing(true)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func changeSearchType(sender: AnyObject) {
        prepareForSelectedSearchType()
        updateUI()
        
    }
    
    func prepareForSelectedSearchType() {
        searchBySoundcloud = searchTypeControl.selectedSegmentIndex == 0
        
        if searchBySoundcloud {
            searchResultsArray = []
            searchResultsTable.reloadData()
            noSearchResults = false
            searchResultsTable.hidden = false
            favoritesTable.hidden = true
            searchBar.hidden = false
        } else {
            searchResultsTable.hidden = true
            favoritesTable.hidden = false
            searchBar.hidden = true
        }
        
    }
    
    override func updateUI() {
        super.updateUI()
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if UserManager.sharedUser.setup == true {
                
                if searchBySoundcloud {
                    
                } else {
                    
                }
                
            } else {
//                setViewInfoHidden(true)
//                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
//                disableButtons()
                searchResultsArray = []
                searchResultsTable.reloadData()
            }
        } else {
//            setViewInfoHidden(true)
//            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
//            disableButtons()
            searchResultsArray = []
            searchResultsTable.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        osvcVariables.screenName = AddSongViewControllerNibName
        
        toolbar.delegate = self
        toolbar.setBackgroundImage(UIImage(named: "toolbarBackground"), forToolbarPosition: UIBarPosition.TopAttached, barMetrics: UIBarMetrics.Default)
        toolbar.setShadowImage(UIImage(named: "navigationBarShadow"), forToolbarPosition: UIBarPosition.TopAttached)
        toolbar.translucent = false
        
        // Setup nav bar
        navigationItem.title = "Add Song"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        
        // Stop view from being covered by the nav bar / laid out from top of screen
        edgesForExtendedLayout = UIRectEdge.None

        let nib = UINib(nibName: SongSearchResultCellNibName, bundle: nil)
        searchResultsTable.registerNib(nib, forCellReuseIdentifier: SongSearchResultCellIdentifier)
        // Creating an (empty) footer stops table from showing empty cells
        searchResultsTable.tableFooterView = UIView(frame: CGRectZero)
        
        // Setup the search bar
        songSearchBar.delegate = self
        songSearchBar.enablesReturnKeyAutomatically = true
        songSearchBar.layer.borderWidth = 1
        songSearchBar.layer.borderColor = UIColor.grayLight().CGColor
        
        let tap = UITapGestureRecognizer(target: self, action: "tap")
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Setup loading animation
        //animatedOneSoundOne.animationImages = [loadingOSLogo2, loadingOSLogo1, loadingOSLogo0, loadingOSLogo1]
        //animatedOneSoundOne.animationDuration = 1.5
        //animatedOneSoundOne.hidden = true
        activityIndicator.hidden = true
        
        addSongFavoritesTableViewController.parentAddSongViewController = self
        addSongFavoritesTableViewController.dataHelper.tableView = favoritesTable
        searchResultsTable.hidden = false
        favoritesTable.backgroundColor = UIColor.grayLight()
        favoritesTable.hidden = true
        addSongFavoritesTableViewController.viewDidLoad()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        searchResultsArray = []
        searchResultsTable.reloadData()
        noSearchResults = false
        
        addSongFavoritesTableViewController.viewDidDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Makes it look like the toolbar is part of the navigation bar
        addSongFavoritesTableViewController.viewWillAppear(animated)
        
        navigationController?.navigationBar.translucent = false
        navigationController?.navigationBar.shadowImage = UIImage()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        addSongFavoritesTableViewController.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        addSongFavoritesTableViewController.viewWillDisappear(animated)
        
        // Restore nav and toolbar appearance
        getFrontNavigationController()?.setupNavigationAndToolbarAppearance()
    }
    
    
    func tap() {
        // Dismiss the keyboard whenever the background is touched while editing
        view.endEditing(true)
    }
    
    func loadingAnimationShouldBeAnimating(animating: Bool) {
        if animating {
            //animatedOneSoundOne.hidden = false
            //animatedOneSoundOne.startAnimating()
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
        } else {
            //animatedOneSoundOne.hidden = true
            //animatedOneSoundOne.stopAnimating()
            activityIndicator.hidden = true
            activityIndicator.stopAnimating()
        }
    }
}

extension AddSongViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultsArray.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if !noSearchResults {
            tableView.backgroundView = nil
            return 1
        } else {
            // Display a message when the table is empty after searching
            setTableBackgroundViewWithMessages(tableView, "No songs found", "Please try searching with a different name")
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = searchResultsTable.dequeueReusableCellWithIdentifier(SongSearchResultCellIdentifier, forIndexPath: indexPath) as! SongSearchResultCell
        let result = searchResultsArray[indexPath.row]

        var nameText: String = (result.name != nil) ? result.name! : ""
        var artistText: String = (result.artistName != nil) ? "Uploaded by \(result.artistName!)" : ""
        var durationText: String = (result.duration != nil) ? timeInSecondsToFormattedMinSecondTimeLabelString(result.duration!) : ""
        var popularityText: String = (result.numberOfPlaybacks != nil) ? "\(thousandsFormatter.stringFromNumber(NSNumber(integer: result.numberOfPlaybacks!))!) playbacks" : ""
        
        cell.nameLabel.text = nameText
        cell.artistNameLabel.text = artistText
        cell.durationLabel.text = durationText
        cell.popularityLabel.text = popularityText
        
        return cell
    }
}

extension AddSongViewController: UITableViewDelegate {
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedSong = searchResultsArray[indexPath.row]
        let source = "sc"
        
        if UserManager.sharedUser.setup == true {
            let partyManager = PartyManager.sharedParty
            if partyManager.state != .None {

                OSAPI.sharedClient.POSTSong(PartyManager.sharedParty.partyID, externalID: selectedSong.externalID, source: source, title: selectedSong.name, artist: selectedSong.artistName, duration: selectedSong.duration, artworkURL: selectedSong.artworkURL,
                    success: { data, responseObject in
                        // If no song playing when song added, bring them to the Now Playing tab
                        if !partyManager.hasCurrentSongAndUser && partyManager.state == .HostStreamable {
                            getPartyTabBarController()?.selectedIndex = 1
                        }
                        self.dismissViewControllerAnimated(true, completion: nil)
                        NSNotificationCenter.defaultCenter().postNotificationName(PartySongWasAddedNotification, object: nil)
                    }, failure: { task, error in
                        self.dismissViewControllerAnimated(true, completion: nil)
                        let alert = UIAlertView(title: "Problem Adding Song", message: "The song could not be added to the playlist, please try a different song", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                        AlertManager.sharedManager.showAlert(alert)
                    }
                )
            } else {
                let alert = UIAlertView(title: "Not A Party Member", message: "Please join a party before adding a song", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                AlertManager.sharedManager.showAlert(alert)
            }
        } else {
            let alert = UIAlertView(title: "Not Signed In", message: "Please sign into an account before adding a song", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
            AlertManager.sharedManager.showAlert(alert)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return heightForRows
    }
}

extension AddSongViewController: UIScrollViewDelegate {
    // MARK: UIScrollViewDelegate
    
    // Dismisses the keyboard when the user was editing text after searching, then looks at results again
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        songSearchBar.resignFirstResponder()
    }
}

extension AddSongViewController: UISearchBarDelegate {
    // MARK: UISearchBarDelegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        /*if countElements(searchText) >= TypingSearchThreshold {
            search(searchTextLength:countElements(searchText), isSearchButtonPressed:false)
        }*/
        
        // Clear search data (this should happen when user presses the 'x' on the right side)
        searchLength = count(searchText)
        if count(searchText) == 0 {
            noSearchResults = false
            searchResultsArray = []
            searchResultsTable.reloadData()
            firstTypingSearch = true
            songSearchTimer.invalidate()
        } else {
            songSearchTimer.invalidate()
            songSearchTimer = NSTimer.scheduledTimerWithTimeInterval(typingSearchServicePeriod, target: self, selector: "search", userInfo: nil, repeats: false)
        }
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.placeholder = nil
        firstTypingSearch = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.placeholder = songSearchBarPlaceholderText
    }
    
    // Hide keyboard when user presses "Search", initiate the search
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        songSearchBar.resignFirstResponder()
        search(isSearchButtonPressed:true)
    }
}


extension AddSongViewController: UIToolbarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}


