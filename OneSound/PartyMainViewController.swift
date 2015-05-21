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

class PartyMainViewController: OSViewController {
    
    let currentSongImageCache = (UIApplication.sharedApplication().delegate as! AppDelegate).currentSongImageCache
    let userCurrentSongImageCache = (UIApplication.sharedApplication().delegate as! AppDelegate).userCurrentSongImageCache
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    
    @IBOutlet weak var songImage: UIImageView?
    @IBOutlet weak var soundcloudLogo: UIImageView?
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var pauseButton: UIButton?
    @IBOutlet weak var songProgress: UIProgressView?
    @IBOutlet weak var songNameLabel: OSLabel!
    @IBOutlet weak var songArtistLabel: OSLabel!
    @IBOutlet weak var songTimeLabel: OSLabel!
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
    
    var createPartyButton: UIBarButtonItem!
    var leavePartyButton: UIBarButtonItem!
    var partySettingsButton: UIBarButtonItem!
    var rightBarButton: UIBarButtonItem?
    
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
        PartyManager.sharedParty.audioManager.onPlayButton()
    }
    
    @IBAction func pause(sender: AnyObject) {
        PartyManager.sharedParty.audioManager.onPauseButton()
    }
    
    @IBAction func addSong(sender: AnyObject) {
        let addSongViewController = AddSongViewController(nibName: AddSongViewControllerNibName, bundle: nil)
        let navC = UINavigationController(rootViewController: addSongViewController)
        presentViewController(navC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        osvcVariables.screenName = PartyMainViewControllerNibName
        
        // Stops bottom of view from flowing under tab bar, but not top, for some reason
        edgesForExtendedLayout = UIRectEdge.None
        
        // This is the delegate to the PartyManager
        PartyManager.sharedParty.delegate = self
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshIfVisible", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and UserManager is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshIfVisible", name: UserManagerInformationDidChangeNotification, object: nil)
        // Should update when a party song is added
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: PartySongWasAddedNotification, object: nil)
        // Refreshes after party state changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: PartyManagerStateChangeNotification, object: nil)
        // Refreshes after the song changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: PartyCurrentSongDidChangeNotification, object: nil)
        // Refreshes when audio state changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: PartyAudioManagerStateChangeNotification, object: nil)
        
        songProgress!.progress = 0.0
        
        // Setup the labels
        setupOSLabelToDefaultDesiredLook(songNameLabel!)
        setupOSLabelToDefaultDesiredLook(songArtistLabel!)
        setupOSLabelToDefaultDesiredLook(songTimeLabel!)
        
        // Setup the thumb up/down buttons
        shortThumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Disabled)
        shortThumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Disabled)
        
        // Setup the add song button
        addSongButton.backgroundColor = UIColor.blue()
        addSongButton.layer.cornerRadius = 3.0
        
        tallUserImage.layer.cornerRadius = 5.0
        tallUserImage.image = defaultUserImageForMainParty
        
        createPartyButton = UIBarButtonItem(title: "Create", style: UIBarButtonItemStyle.Plain, target: self, action: "createParty")
        leavePartyButton = UIBarButtonItem(title: "Leave", style: UIBarButtonItemStyle.Plain, target: self, action: "leaveParty")
        leavePartyButton.tintColor = UIColor.red()
        partySettingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: "changePartySettings")
        rightBarButton = createPartyButton

        hideMessages()
        setPartyInfoHidden(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let party = PartyManager.sharedParty
        
        // Also update the nav bar title and right bar button before the networking call in refresh 
        // Otherwise will lag when changing tabs
        if party.state != .None {
            self.parentViewController!.navigationItem.title = party.name
        }
        else {
            self.parentViewController!.navigationItem.title = "Now Playing"
        }
        setRightBarButtonWhenSelected()
        
        party.refresh(completion: {
            if party.state != .None {
                self.parentViewController!.navigationItem.title = party.name
            }
            else {
                self.parentViewController!.navigationItem.title = "Now Playing"
            }
            
            self.setRightBarButtonWhenSelected()
            self.refresh()
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func updateRightBarButton(# create: Bool, leave: Bool, settings: Bool) {
        if create { rightBarButton = createPartyButton }
        else if leave { rightBarButton = leavePartyButton }
        else if settings { rightBarButton = partySettingsButton }
        else { rightBarButton = nil }
        setRightBarButtonWhenSelected()
    }
    
    // When this is the selected tab of the tab bar controller, set the right nav button to rightBarButton
    func setRightBarButtonWhenSelected() {
        getPartyTabBarController()?.updateRightBarButtonForMainParty()
    }
}

extension PartyMainViewController {
    // MARK: Refreshing
    
    func refresh() {
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if UserManager.sharedUser.setup == true {
                refreshForValidUserAndReachableNetwork()
            } else {
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
                updateRightBarButton(create: false, leave: false, settings: false)
                setPartyInfoHidden(true)
            }
        } else {
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
            updateRightBarButton(create: false, leave: false, settings: false)
            setPartyInfoHidden(true)
        }
    }
    
    private func refreshForValidUserAndReachableNetwork() {
        let partyState = PartyManager.sharedParty.state
        
        if partyState != .None { hideMessages(); setPartyInfoHidden(false) }
        if partyState != .HostStreamable { hideAudioPlayerButtons() }
        
        switch partyState {
        case .Member:
            updateRightBarButton(create: false, leave: true, settings: false)
            showAddSongButtonIfNoCurrentSong()
            updateCurrentSongAndUserInfo()
            
        case .Host:
            updateRightBarButton(create: false, leave: false, settings: true)
            showAddSongButtonIfNoCurrentSong()
            updateCurrentSongAndUserInfo()
            
        case .HostStreamable:
            updateRightBarButton(create: false, leave: false, settings: true)
            refreshForHostStreamableFromAudioManagerState()
            
        case .None:
            showMessages("Not member of a party", detailLine: "Become a party member by joining or creating a party")
            updateRightBarButton(create: true, leave: false, settings: false)
            setPartyInfoHidden(true) // Also hides the audio buttons and add song button
        }
    }
    
    private func refreshForHostStreamableFromAudioManagerState() {
        let audioManagerState = PartyManager.sharedParty.audioManager.state
        switch audioManagerState {
        case .Inactive:
            setAddSongButtonHidden(false)
            clearAllCurrentSongAndUserInfo()
            hideAudioPlayerButtons()
            
        case .Empty:
            setAddSongButtonHidden(false)
            clearAllCurrentSongAndUserInfo()
            hideAudioPlayerButtons()
            
        case .Paused:
            setAddSongButtonHidden(true)
            updateCurrentSongAndUserInfo()
            setAudioPlayerButtonsForPlaying(false)
            
        case .Playing:
            setAddSongButtonHidden(true)
            updateCurrentSongAndUserInfo()
            setAudioPlayerButtonsForPlaying(true)
        }
    }
    
    func refreshIfVisible() {
        if isViewLoaded() && view.window != nil {
            refresh()
        }
    }
}

extension PartyMainViewController {
    // MARK: Current song info setting/hiding

    func updateCurrentSongProgress(progress: Float) {
        songProgress!.progress = progress
        songProgress!.hidden = false
    }
    
    func updateCurrentSongAndUserInfo() {
        let party = PartyManager.sharedParty
        if party.hasCurrentSongAndUser {
            let currentSong = party.currentSong!
            let currentUser = party.currentUser!
            
            var thumbsUp = false
            var thumbsDown = false
            
            if currentSong.userVote != nil {
                switch currentSong.userVote! {
                case .Up:
                    thumbsUp = true
                case .Down:
                    thumbsDown = true
                default:
                    break
                }
            }
            
            setCurrentSongUserInfo(currentUser, thumbsUp: thumbsUp, thumbsDown: thumbsDown)
            setCurrentSongInfo(name: currentSong.name, artist: currentSong.artistName, time: timeInSecondsToFormattedMinSecondTimeLabelString(currentSong.duration))
            updateSongImage()
        } else {
            clearAllCurrentSongAndUserInfo()
        }
    }
    
    func clearAllCurrentSongAndUserInfo() {
        setCurrentSongImage(songToPlay: false, artworkToShow: false, image: nil)
        setCurrentSongInfo(name: "", artist: "", time: "")
        setCurrentSongUserInfo(nil, thumbsUp: false, thumbsDown: false)
        resetThumbsUpDownButtons()
    }
    
    func setCurrentSongUserInfo(user: User?, thumbsUp: Bool, thumbsDown: Bool) {
        showCurrentSongUserInfo()
        setThumbsUpDownButtons(thumbsUp, thumbsDown: thumbsDown)
        
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
                    setUserImageUsingCache(user!.photoURL!)
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
    
    func setCurrentSongInfo(# name: String, artist: String, time: String) {
        showCurrentSongInfo()
        
        songNameLabel.attributedText =
            NSAttributedString(
                string: name,
                attributes:
                [
                    NSFontAttributeName: songNameLabel.font,
                    NSForegroundColorAttributeName: songNameLabel.textColor,
                    NSKernAttributeName: songNameLabel.kerning
                ])
        songArtistLabel.attributedText =
            NSAttributedString(
                string: artist,
                attributes:
                [
                    NSFontAttributeName: songArtistLabel.font,
                    NSForegroundColorAttributeName: songArtistLabel.textColor,
                    NSKernAttributeName: songArtistLabel.kerning
                ])
        songTimeLabel.attributedText =
            NSAttributedString(
                string: time,
                attributes:
                [
                    NSFontAttributeName: songTimeLabel.font,
                    NSForegroundColorAttributeName: songTimeLabel.textColor,
                    NSKernAttributeName: songTimeLabel.kerning
                ])
        
        songNameLabel!.adjustFontSizeToFit(minFontSize: 16, heightToAdjustFor: 25)
    }
    
    func showCurrentSongUserInfo() {
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
    
    func showCurrentSongInfo() {
        songNameLabel!.hidden = false
        songArtistLabel!.hidden = false
        songTimeLabel!.hidden = false
        songProgress!.hidden = false
    }
    
    // Hides the add song button if there's a song and user, else shows it
    func showAddSongButtonIfNoCurrentSong() {
        addSongButton.hidden = PartyManager.sharedParty.hasCurrentSongAndUser
    }
    
    func setAddSongButtonHidden(hidden: Bool) {
        addSongButton.hidden = hidden
    }
}

extension PartyMainViewController {
    // MARK: Song image setting/downloading
    
    func updateSongImage() {
        let party = PartyManager.sharedParty
        
        if let artworkURL = party.currentSong?.artworkURL {
            
            let largerArtworkURL = artworkURL.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
            
            currentSongImageCache.queryDiskCacheForKey(largerArtworkURL,
                done: { image, imageCacheType in
                    if image != nil {
                        self.setCurrentSongImage(songToPlay: true, artworkToShow: true, image: image)
                    } else {
                        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: largerArtworkURL), options: nil, progress: nil,
                            completed: { image, error, cacheType, boolValue, url in
                                if error == nil && image != nil {
                                    self.currentSongImageCache.storeImage(image, forKey: largerArtworkURL)
                                    self.setCurrentSongImage(songToPlay: true, artworkToShow: true, image: image)
                                } else {
                                    self.setCurrentSongImage(songToPlay: true, artworkToShow: false, image: nil)
                                }
                            }
                        )
                    }
                }
            )
        } else {
            setCurrentSongImage(songToPlay: true, artworkToShow: false, image: nil)
        }
    }
    
    func setCurrentSongImage(# songToPlay: Bool, artworkToShow: Bool, image: UIImage?) {
        addSongButton.hidden = true
        songImage!.hidden = false
        
        if !songToPlay {
            songImage!.image = songImageForNoSongToPlay
            addSongButton.hidden = false
            soundcloudLogo!.hidden = true
            return
        }
        
        soundcloudLogo!.hidden = false
        
        if !artworkToShow {
            songImage!.image = songImageForNoSongArtwork
            soundcloudLogo!.hidden = false
            return
        }
        
        if image != nil {
            songImage!.image = image
            //songImage = UIImageView(image: image)
        } else {
            songImage!.image = songImageForNoSongArtwork
        }
    }
}

extension PartyMainViewController {
    // MARK: Song user image setting/downloading
    
    // Sets the user image from the cache if it's there, else downloads and caches it before setting
    func setUserImageUsingCache(urlString: String) {
        userCurrentSongImageCache.queryDiskCacheForKey(urlString,
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
                    
                    self.userCurrentSongImageCache.storeImage(processedImage, forKey: urlString)
                    
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

extension PartyMainViewController {
    // MARK: play/pause buttons
    
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
    
    func hideAudioPlayerButtons() {
        pauseButton!.hidden = true
        playButton!.hidden = true
    }
}

extension PartyMainViewController {
    // MARK: Thumbs up/down button handling
    
    func setThumbsUpDownButtons(thumbsUp: Bool, thumbsDown: Bool) {
        if thumbsUp {
            setThumbsUpSelected()
            setThumbsDownUnselected()
        } else if thumbsDown {
            setThumbsDownSelected()
            setThumbsUpUnselected()
        } else {
            resetThumbsUpDownButtons()
        }
    }
    
    func handleThumbsUpPress(button: AnyObject) {
        if let thumbsUpButton = button as? UIButton {
            if thumbsUpButton.selected {
                // If the button is selected before it is pressed, make it unselected
                setThumbsUpUnselected()
                
                // Clear song vote
                if let currentSong = PartyManager.sharedParty.currentSong {
                    PartyManager.sharedParty.songClearVote(currentSong.songID)
                }
                changeUserUpvoteLabelCountBy(-1)
            } else {
                // If the button is unselected before it is pressed
                setThumbsUpSelected()
                
                // Upvote song
                if let currentSong = PartyManager.sharedParty.currentSong {
                    PartyManager.sharedParty.songUpvote(currentSong.songID)
                }
                changeUserUpvoteLabelCountBy(1)
                
                if shortThumbsDownButton.selected || tallThumbsDownButton.selected {
                    setThumbsDownUnselected()
                    changeUserUpvoteLabelCountBy(1)
                }
            }
        }
    }
    
    func handleThumbsDownPress(button: AnyObject) {
        if let thumbsDownButton = button as? UIButton {
            if thumbsDownButton.selected {
                // If the button is selected before it is pressed, make it unselected
                setThumbsDownUnselected()
                
                // Clear song vote
                if let currentSong = PartyManager.sharedParty.currentSong {
                    PartyManager.sharedParty.songClearVote(currentSong.songID)
                }
                changeUserUpvoteLabelCountBy(1)
            } else {
                // If the button is unselected before it is pressed
                setThumbsDownSelected()
                
                // Downvote song
                if let currentSong = PartyManager.sharedParty.currentSong {
                    PartyManager.sharedParty.songDownvote(currentSong.songID)
                }
                changeUserUpvoteLabelCountBy(-1)
                
                if shortThumbsUpButton.selected || tallThumbsUpButton.selected {
                    setThumbsUpUnselected()
                    changeUserUpvoteLabelCountBy(-1)
                }
            }
        }
    }
    
    func resetThumbsUpDownButtons() {
        setThumbsUpUnselected()
        setThumbsDownUnselected()
    }
    
    func changeUserUpvoteLabelCountBy(changeBy: Int) {
        if userUpvoteLabel != nil {
            if let voteCount = userUpvoteLabel!.text!.toInt() {
                let newVoteCount = voteCount + changeBy
                userUpvoteLabel.text = String(newVoteCount)
            }
        }
    }
    
    func setThumbsUpSelected() {
        if shorterIphoneScreen {
            shortThumbsUpButton.setImage(thumbsUpSelectedMainParty, forState: UIControlState.Normal)
            shortThumbsUpButton.selected = true
        } else {
            tallThumbsUpButton.setImage(thumbsUpSelectedMainParty, forState: UIControlState.Normal)
            tallThumbsUpButton.selected = true
        }
    }
    
    func setThumbsUpUnselected() {
        if shorterIphoneScreen {
            shortThumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Normal)
            shortThumbsUpButton.selected = false
        } else {
            tallThumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Normal)
            tallThumbsUpButton.selected = false
        }
    }
    
    func setThumbsDownSelected() {
        if shorterIphoneScreen {
            shortThumbsDownButton.setImage(thumbsDownSelectedMainParty, forState: UIControlState.Normal)
            shortThumbsDownButton.selected = true
        } else {
            tallThumbsDownButton.setImage(thumbsDownSelectedMainParty, forState: UIControlState.Normal)
            tallThumbsDownButton.selected = true
        }
    }
    
    func setThumbsDownUnselected() {
        if shorterIphoneScreen {
            shortThumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Normal)
            shortThumbsDownButton.selected = false
        } else {
            tallThumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Normal)
            tallThumbsDownButton.selected = false
        }
    }
}

extension PartyMainViewController {
    // MARK: Hiding/showing party and messages
    
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

extension PartyMainViewController {
    // MARK: Create/leave/change party functions
    
    func createParty() {
        if UserManager.sharedUser.guest == false {
            let createPartyStoryboard = UIStoryboard(name: CreatePartyStoryboardName, bundle: nil)
            let createPartyViewController = createPartyStoryboard.instantiateViewControllerWithIdentifier(CreatePartyViewControllerIdentifier) as! CreatePartyViewController
            createPartyViewController.partyAlreadyExists = false
            createPartyViewController.delegate = self
            
            let navC = UINavigationController(rootViewController: createPartyViewController)
            if let fnc = getFrontNavigationController() {
                fnc.presentViewController(navC, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertView(title: "Guests cannot create parties", message: "To create a party go to the Profile and sign in with Facebook, then try again", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Profile")
            alert.tag = AlertTag.GuestCreatingParty.rawValue
            alert.show()
        }
    }
    
    func leaveParty() {
        PartyManager.sharedParty.leaveParty(
            respondToChangeAttempt: { partyWasLeft in
                if partyWasLeft {
                    self.parentViewController!.navigationItem.title = "Party"
                    self.refresh()
                } else {
                    let alert = UIAlertView(title: "Could not leave party", message: "Please try again, or just create a new one", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                    alert.show()
                }
            }
        )
    }
    
    func changePartySettings() {
        if PartyManager.sharedParty.state == .Host || PartyManager.sharedParty.state == .HostStreamable  {
            let createPartyStoryboard = UIStoryboard(name: CreatePartyStoryboardName, bundle: nil)
            let createPartyViewController = createPartyStoryboard.instantiateViewControllerWithIdentifier(CreatePartyViewControllerIdentifier) as! CreatePartyViewController
            createPartyViewController.partyAlreadyExists = true
            createPartyViewController.delegate = self
            
            let navC = UINavigationController(rootViewController: createPartyViewController)
            if let fnc = getFrontNavigationController() {
                fnc.presentViewController(navC, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertView(title: "Only hosts edit party settings", message: "Please become the host before editing party settings, or make sure you still are the host", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
            alert.show()
        }
    }
}

extension PartyMainViewController: PartyManagerDelegate {
    // MARK: PartyManagerDelegate
    // Other delegate methods fit better in different extensions
    
    func getCurrentSongProgress() -> Float {
        return songProgress!.progress
    }
}

extension PartyMainViewController: CreatePartyViewControllerDelegate {
    // MARK: CreatePartyViewControllerDelegate
    
    func CreatePartyViewControllerDone() {
        //viewWillAppear(true)
    }
}

extension PartyMainViewController: UIAlertViewDelegate {
    // MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == AlertTag.GuestCreatingParty.rawValue {
            // If guest wants to sign in with Facebook, take them to the profile
            if buttonIndex == 1 {
                getAppDelegate()?.sideMenuViewController.programaticallySelectRow(SideMenuRow.Profile.rawValue)
            }
        }
    }
}