//
//  AddSongViewController.swift
//  OneSound
//
//  Created by adam on 8/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let AddSongViewControllerNibName = "AddSongViewController"
let SongSearchResultCellIdentifier = "SongSearchResultCell"
let PartySongWasAddedNotification = "PartySongWasAdded"

let SongDurationMaxInSeconds = 600 // 10 minute max

class AddSongViewController: UIViewController {

    @IBOutlet weak var songSearchTextField: UITextField!
    @IBOutlet weak var searchResultsTable: UITableView!
    @IBOutlet weak var animatedOneSoundOne: UIImageView!
    
    var searchResultsArray = [SongSearchResult]()
    
    let heightForRows: CGFloat = 64.0
    
    var noSearchResults = false
    
    func search() {
        // Hide the keyboard
        songSearchTextField.resignFirstResponder()
        
        // Empty the table, reload to show its empty, start the animation
        noSearchResults = false
        searchResultsArray = []
        searchResultsTable.reloadData()
        loadingAnimationShouldBeAnimating(true)
        
        SCClient.sharedClient.searchSoundCloudForSongWithString(songSearchTextField.text,
            success: {data, responseObject in
                let responseJSON = JSONValue(responseObject)
                //println(responseJSON)
                let songsArray = responseJSON.array
                //println(songsArray!)
                //println(songsArray!.count)
                
                var newSongSearchResults = [SongSearchResult]()
                
                if songsArray != nil {
                    for result in songsArray! {
                        //println(result)
                        let source = "sc"
                        let id = result["id"].integer
                        let name = result["title"].string
                        let artistName = result["user"]["username"].string
                        var duration = result["duration"].integer
                        let artworkURL = result["artwork_url"].string
                        let playbacks = result["playback_count"].integer
                        
                        if duration != nil {
                            // Soundcloud duration is returned in milliseconds; convert to seconds
                            duration! /= 1000
                            if duration < SongDurationMaxInSeconds {
                                newSongSearchResults.append(SongSearchResult(source: source, externalID: id!, name: name!, artistName: artistName!, duration: duration!, artworkURL: artworkURL, numberOfPlaybacks: playbacks))
                            }
                        }
                    }
                }
                
                if newSongSearchResults.count == 0 { self.noSearchResults = true }
                
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
    
    func cancel() {
        view.endEditing(true)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup nav bar
        navigationItem.title = "Add Song"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Search", style: UIBarButtonItemStyle.Plain, target: self, action: "search")
        navigationItem.rightBarButtonItem!.enabled = false
        
        // Stop view from being covered by the nav bar / laid out from top of screen
        edgesForExtendedLayout = UIRectEdge.None

        let nib = UINib(nibName: SongSearchResultCellNibName, bundle: nil)
        searchResultsTable.registerNib(nib, forCellReuseIdentifier: SongSearchResultCellIdentifier)
        // Creating an (empty) footer stops table from showing empty cells
        searchResultsTable.tableFooterView = UIView(frame: CGRectZero)
        
        songSearchTextField.delegate = self
        songSearchTextField.enablesReturnKeyAutomatically = true
        songSearchTextField.addTarget(self, action: "textFieldDidChange", forControlEvents: UIControlEvents.EditingChanged)
        
        let tap = UITapGestureRecognizer(target: self, action: "tap")
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Setup loading animation
        animatedOneSoundOne.animationImages = [loadingOSLogo2, loadingOSLogo1, loadingOSLogo0, loadingOSLogo1]
        animatedOneSoundOne.animationDuration = 1.5
        animatedOneSoundOne.hidden = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        searchResultsArray = []
        searchResultsTable.reloadData()
        noSearchResults = false
    }
    
    func textFieldDidChange() {
        if countElements(songSearchTextField.text as String) > 0 {
            navigationItem.rightBarButtonItem!.enabled = true
        } else {
            navigationItem.rightBarButtonItem!.enabled = false
        }
    }
    
    func tap() {
        // Dismiss the keyboard whenever the background is touched while editing
        view.endEditing(true)
    }
    
    func loadingAnimationShouldBeAnimating(shouldBeAnimating: Bool) {
        if shouldBeAnimating {
            animatedOneSoundOne.hidden = false
            animatedOneSoundOne.startAnimating()
        } else {
            animatedOneSoundOne.hidden = true
            animatedOneSoundOne.stopAnimating()
        }
    }
}

extension AddSongViewController: UITableViewDataSource {
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
        let cell = searchResultsTable.dequeueReusableCellWithIdentifier(SongSearchResultCellIdentifier, forIndexPath: indexPath) as SongSearchResultCell
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
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let selectedSong = searchResultsArray[indexPath.row]
        let source = "sc"
        
        if UserManager.sharedUser.setup == true {
            if PartyManager.sharedParty.setup == true {

                OSAPI.sharedClient.POSTSong(PartyManager.sharedParty.partyID, externalID: selectedSong.externalID, source: source, title: selectedSong.name, artist: selectedSong.artistName, duration: selectedSong.duration, artworkURL: selectedSong.artworkURL,
                    success: { data, responseObject in
                        self.dismissViewControllerAnimated(true, completion: nil)
                        NSNotificationCenter.defaultCenter().postNotificationName(PartySongWasAddedNotification, object: nil)
                    }, failure: { task, error in
                        self.dismissViewControllerAnimated(true, completion: nil)
                        let alert = UIAlertView(title: "Problem Adding Song", message: "The song could not be added to the playlist, please try a different song", delegate: nil, cancelButtonTitle: "Ok")
                        alert.show()
                    }
                )
            } else {
                let alert = UIAlertView(title: "Not A Party Member", message: "Please join a party before adding a song", delegate: nil, cancelButtonTitle: "Ok")
                alert.show()
            }
        } else {
            let alert = UIAlertView(title: "Not Signed In", message: "Please sign into an account before adding a song", delegate: nil, cancelButtonTitle: "Ok")
            alert.show()
        }
    }
    
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return heightForRows
    }
}

extension AddSongViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        // Hide keyboard when user presses "Search", initiate the search
        search()
        return true
    }
}


