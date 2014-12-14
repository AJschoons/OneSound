//
//  PartyMainViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit
import AVFoundation

let PartyMainViewControllerNibName = "PartyMainViewController"
let PlayPauseButtonAnimationTime = 0.2

let defaultUserImageForMainParty = UIImage(named: "defaultUserImageForMainParty")

let songImageForNoSongToPlay = UIImage(named: "noSongToPlay")
let songImageForNoSongArtwork = UIImage(named: "songImageForNoSongArtwork")

let thumbsUpSelectedMainParty = UIImage(named: "thumbsUpSelectedMainParty")
let thumbsUpUnselectedMainParty = UIImage(named: "thumbsUpUnselectedMainParty")
let thumbsDownSelectedMainParty = UIImage(named: "thumbsDownSelectedMainParty")
let thumbsDownUnselectedMainParty = UIImage(named: "thumbsDownUnselectedMainParty")

class PartyMainViewController: UIViewController {
    
    let userMainPartyImageCache = (UIApplication.sharedApplication().delegate as AppDelegate).userMainPartyImageCache
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    
    @IBOutlet weak var songImage: UIImageView?
    @IBOutlet weak var soundcloudLogo: UIImageView?
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var pauseButton: UIButton?
    @IBOutlet weak var songProgress: UIProgressView?
    @IBOutlet weak var songNameLabel: THLabel?
    @IBOutlet weak var songArtistLabel: THLabel?
    @IBOutlet weak var songTimeLabel: THLabel?
    @IBOutlet weak var songImageForLoadingSong: UIImageView!
    @IBOutlet weak var addSongButton: UIButton!
    
    
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var shortUserLabel: UILabel!
    @IBOutlet weak var shortThumbsDownButton: UIButton!
    @IBOutlet weak var shortThumbsUpButton: UIButton!
    @IBOutlet weak var tallUserLabel: UILabel!
    @IBOutlet weak var tallThumbsDownButton: UIButton!
    @IBOutlet weak var tallThumbsUpButton: UIButton!
    @IBOutlet weak var tallUserImage: UIImageView!
    
    @IBOutlet weak var userUpvoteLabel: UILabel!
    @IBOutlet weak var userSongLabel: UILabel!
    @IBOutlet weak var userHotnessLabel: UILabel!
    @IBOutlet weak var userUpvoteIcon: UIImageView!
    @IBOutlet weak var userSongIcon: UIImageView!
    @IBOutlet weak var userHotnessIcon: UIImageView!
    
    var partyRefreshTimer: NSTimer?
    
    @IBAction func tallThumbsDownPressed(sender: AnyObject) {
        handleThumbsDownPress(sender)
    }
    
    @IBAction func tallThumbsUpPressed(sender: AnyObject) {
        handleThumbsUpPress(sender)
    }
  
    @IBAction func shortThumbsDownPressed(sender: AnyObject) {
        handleThumbsDownPress(sender)
    }
    
    @IBAction func shortThumbsUpPressed(sender: AnyObject) {
        handleThumbsUpPress(sender)
    }
    
    
    
    @IBAction func play(sender: AnyObject) {
        LocalParty.sharedParty.playSong()
    }
    
    @IBAction func pause(sender: AnyObject) {
        LocalParty.sharedParty.pauseSong()
    }
    
    @IBAction func addSong(sender: AnyObject) {
        let addSongViewController = AddSongViewController(nibName: AddSongViewControllerNibName, bundle: nil)
        let navC = UINavigationController(rootViewController: addSongViewController)
        presentViewController(navC, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        // This is the delegate to the LocalParty
        LocalParty.sharedParty.delegate = self
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        // Should update when a party song is added
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshAfterAddingSong", name: PartySongWasAddedNotification, object: nil)
        
        songProgress!.progress = 0.0
        
        // Setup the labels
        setupTHLabelToDefaultDesiredLook(songNameLabel!)
        setupTHLabelToDefaultDesiredLook(songArtistLabel!)
        setupTHLabelToDefaultDesiredLook(songTimeLabel!)
        songNameLabel!.textInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        songArtistLabel!.textInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        songArtistLabel!.shadowColor = UIColor(white: 0, alpha: 0.3)
        songTimeLabel!.textInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        songTimeLabel!.shadowColor = UIColor(white: 0, alpha: 0.3)
        
        // Setup loading animation
        songImageForLoadingSong.animationImages = [loadingSong2, loadingSong1, loadingSong0, loadingSong1]
        songImageForLoadingSong.animationDuration = 1.5
        songImageForLoadingSong.hidden = true
        
        // Setup the thumb up/down buttons
        shortThumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Disabled)
        shortThumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Disabled)
        
        // Setup the add song button
        addSongButton.backgroundColor = UIColor.blue()
        addSongButton.layer.cornerRadius = 3.0
        
        tallUserImage.layer.cornerRadius = 5.0
        tallUserImage.image = defaultUserImageForMainParty
        
        hideMessages()
        setPartyInfoHidden(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let party = LocalParty.sharedParty
        if party.setup == true && party.name != nil {
            navigationController!.visibleViewController.title = LocalParty.sharedParty.name
            if !party.userIsHost {
                partyRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "refresh", userInfo: nil, repeats: true)
            }
        }
        else {
            navigationController!.visibleViewController.title = "Party"
        }
        
        refresh()
    }
    
    override func viewWillDisappear(animated: Bool) {
        if partyRefreshTimer != nil { partyRefreshTimer!.invalidate() }
    }
    
    func handleThumbsUpPress(button: AnyObject) {
        if let thumbsUpButton = button as? UIButton {
            if thumbsUpButton.selected {
                // If the button is selected before it is pressed, make it unselected
                thumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Normal)
                thumbsUpButton.selected = false
            } else {
                // If the button is unselected before it is pressed
                thumbsUpButton.setImage(thumbsUpSelectedMainParty, forState: UIControlState.Normal)
                thumbsUpButton.selected = true
                
                if shorterIphoneScreen {
                    if shortThumbsDownButton.selected {
                        handleThumbsDownPress(shortThumbsDownButton)
                    }
                } else {
                    if tallThumbsDownButton.selected {
                        handleThumbsDownPress(tallThumbsDownButton)
                    }
                }
            }
        }
    }
    
    func handleThumbsDownPress(button: AnyObject) {
        if let thumbsDownButton = button as? UIButton {
            if thumbsDownButton.selected {
                // If the button is selected before it is pressed, make it unselected
                thumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Normal)
                thumbsDownButton.selected = false
            } else {
                // If the button is unselected before it is pressed
                thumbsDownButton.setImage(thumbsDownSelectedMainParty, forState: UIControlState.Normal)
                thumbsDownButton.selected = true
                
                if shorterIphoneScreen {
                    if shortThumbsUpButton.selected {
                        handleThumbsUpPress(shortThumbsUpButton)
                    }
                } else {
                    if tallThumbsUpButton.selected {
                        handleThumbsUpPress(tallThumbsUpButton)
                    }
                }
            }
        }
    }
    
    func resetThumbsUpDownButtons() {
        if shorterIphoneScreen {
            shortThumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Normal)
            shortThumbsUpButton.selected = false
            
            shortThumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Normal)
            shortThumbsDownButton.selected = false
        } else {
            tallThumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Normal)
            tallThumbsUpButton.selected = false
            
            tallThumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Normal)
            tallThumbsDownButton.selected = false
        }
    }
    
    func updateSongProgress(progress: Float) {
        songProgress!.progress = progress
        songProgress!.hidden = false
    }
    
    func onPartyRefreshTimer() {
        if !LocalParty.sharedParty.userIsHost { refresh() }
    }
    
    func refreshAfterAddingSong() {
        addSongButton.hidden = true
        refresh()
    }
    
    func refresh() {
        println("refreshing PartyMainViewController")
        LocalParty.sharedParty.refresh()
    }
    
    func clearSongInfo() {
        setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: false, image: nil)
        setPartySongInfo(songName: "", songArtist: "", songTime: "", user: nil)
        resetThumbsUpDownButtons()
    }
    
    func setPartySongUserInfo(user: User?) {
        showPartySongUserInfo()
        
        if shorterIphoneScreen {
            if user != nil {
                shortUserLabel.text = user!.name
            } else {
                shortUserLabel.text = ""
                shortUserLabel.hidden = true
                shortThumbsUpButton.hidden = true
                shortThumbsDownButton.hidden = true
            }
        } else {
            if user != nil {
                setUserInfoLabelsText(upvoteLabel: userUpvoteLabel, numUpvotes: user!.upvoteCount, songLabel: userSongLabel, numSongs: user!.songCount, hotnessLabel: userHotnessLabel, percentHotness: user!.hotnessPercent, userNameLabel: tallUserLabel, userName: user!.name)
                
                tallUserImage.image = defaultUserImageForMainParty
                if user!.photoURL != nil {
                    setUserMainPartyImageUsingCache(user!.photoURL!)
                }
            } else {
                tallUserLabel.text = ""
                tallThumbsUpButton.hidden = true
                tallThumbsDownButton.hidden = true
                tallUserImage.hidden = true
                
                userUpvoteLabel.text = ""
                userSongLabel.text = ""
                userHotnessLabel.text = ""
                userUpvoteLabel.hidden = true
                userSongLabel.hidden = true
                userHotnessLabel.hidden = true
                userUpvoteIcon.hidden = true
                userSongIcon.hidden = true
                userHotnessIcon.hidden = true
            }
        }
    }
    
    func showPartySongUserInfo() {
        userView!.hidden = false
        
        if shorterIphoneScreen {
            shortUserLabel.hidden = false
            shortThumbsDownButton.hidden = false
            shortThumbsUpButton.hidden = false
        } else {
            tallUserLabel.hidden = false
            tallThumbsDownButton.hidden = false
            tallThumbsUpButton.hidden = false
            tallUserImage.hidden = false
            
            userUpvoteLabel.hidden = false
            userSongLabel.hidden = false
            userHotnessLabel.hidden = false
            userUpvoteIcon.hidden = false
            userSongIcon.hidden = false
            userHotnessIcon.hidden = false
        }
    }
    
    func showPartySongInfo() {
        songNameLabel!.hidden = false
        songArtistLabel!.hidden = false
        songTimeLabel!.hidden = false
        songProgress!.hidden = false
    }
    
    func setPartySongInfo(# songName: String, songArtist: String, songTime: String, user: User?) {
        showPartySongInfo()
        
        songNameLabel!.text = songName
        songArtistLabel!.text = songArtist
        songTimeLabel!.text = songTime
        
        setPartySongUserInfo(user)
    }
    
    func setPartySongImage(# songToPlay: Bool, artworkToShow: Bool, loadingSong: Bool, image: UIImage?) {
        addSongButton.hidden = true
        
        if loadingSong {
            songImage!.hidden = true
            
            songImageForLoadingSong.hidden = false
            songImageForLoadingSong.startAnimating()
            soundcloudLogo!.hidden = false
            return
        } else {
            songImage!.hidden = false
            
            songImageForLoadingSong.hidden = true
            songImageForLoadingSong.stopAnimating()
        }
        
        if !songToPlay {
            songImage!.image = songImageForNoSongToPlay
            addSongButton.hidden = false
            soundcloudLogo!.hidden = true
            return
        }
        
        if !artworkToShow {
            songImage!.image = songImageForNoSongArtwork
            soundcloudLogo!.hidden = false
            return
        }
        
        soundcloudLogo!.hidden = false
        
        if image != nil {
            songImage!.image = image
            //songImage = UIImageView(image: image)
        } else {
            songImage!.image = songImageForNoSongArtwork
        }
    }
    
    func setPartyInfoHidden(hidden: Bool) {
        if songImage != nil {
            songImage!.hidden = hidden
        }
        
        songNameLabel!.hidden = hidden
        songArtistLabel!.hidden = hidden
        songTimeLabel!.hidden = hidden
        
        // Only set button visibility for hiding; to show them the player must be checked
        // Only set the songImageOverlay to hidden, don't set it to visible with everything else
        // When hiding the party info, reset the song labels to empty and the song progress to 0
        if hidden == true {
            songImageForLoadingSong.hidden = hidden
            
            soundcloudLogo!.hidden = hidden
            
            playButton!.hidden = hidden
            playButton!.alpha = 0.0
            pauseButton!.hidden = hidden
            pauseButton!.alpha = 0.0
            songProgress!.hidden = hidden
            songProgress!.alpha = 0.0
            songProgress!.progress = 0.0
            addSongButton.hidden = hidden
            
            songNameLabel!.text = ""
            songArtistLabel!.text = ""
            songTimeLabel!.text = ""
            
            userView!.hidden = hidden
            if shorterIphoneScreen {
                shortUserLabel!.hidden = hidden
                shortUserLabel!.text = ""
                shortThumbsDownButton!.hidden = hidden
                shortThumbsUpButton!.hidden = hidden
            } else {
                tallUserLabel!.hidden = hidden
                tallUserLabel!.text = ""
                tallThumbsDownButton!.hidden = hidden
                tallThumbsUpButton!.hidden = hidden
                tallUserImage.hidden = hidden
            }
        }
    }
    
    func setAudioPlayerButtonsForPlaying(audioPlayerIsPlaying: Bool) {
        // The song progress should always be visible when there's an audio player
        songProgress!.hidden = false
        songProgress!.alpha = 1.0
        
        if audioPlayerIsPlaying {
            // Make pause button active
            if playButton!.hidden == false {
                // Play button is visible; hide it and then show the pause button, then fade it out again
                UIView.animateWithDuration(PlayPauseButtonAnimationTime,
                    animations: {
                        self.playButton!.alpha = 0.0
                    },
                    completion: { boolVal in
                        self.playButton!.hidden = true
                        self.pauseButton!.hidden = false
                        self.pauseButton!.alpha = 1.0
                    }
                )
            } else {
                // Play button is not visible, so just make the pause button active
                pauseButton!.hidden = false
                pauseButton!.alpha = 1.0
            }
        } else {
            // Make play button visible and the pause button inactive
            pauseButton!.hidden = true
            pauseButton!.alpha = 0.0
            playButton!.hidden = false
            UIView.animateWithDuration(PlayPauseButtonAnimationTime,
                animations: {
                    self.playButton!.alpha = 1.0
                }
            )
        }
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
    
    // Sets the user image from the cache if it's there, else downloads and caches it before setting
    func setUserMainPartyImageUsingCache(urlString: String) {
        userMainPartyImageCache.queryDiskCacheForKey(urlString,
            done: { image, imageCacheType in
                if image != nil {
                    self.tallUserImage.image = image
                    self.tallUserImage.setNeedsLayout()
                } else {
                    self.startImageDownload(urlString)
                }
            }
        )
    }
    
    // Sets user image after downloading and caching the image at the urlString into the userMainPartyImageCache
    func startImageDownload(urlString: String) {
        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: urlString), options: nil, progress: nil,
            completed: { image, error, cacheType, boolValue, url in
                
                if error == nil && image != nil {
                    let processedImage = cropBiggestCenteredSquareImageFromImage(image, sideLength: self.tallUserImage.frame.height)
                    
                    self.userMainPartyImageCache.storeImage(processedImage, forKey: urlString)
                    
                    dispatchAsyncToMainQueue(action: {
                        self.tallUserImage.image = processedImage
                        self.tallUserImage.setNeedsLayout()
                    })
                } else {
                    dispatchAsyncToMainQueue(action: {
                        self.tallUserImage.image = defaultUserImageForMainParty
                        self.tallUserImage.setNeedsLayout()
                    })
                }
            }
        )
    }
    
    
}

extension PartyMainViewController: LocalPartyDelegate {
    
}