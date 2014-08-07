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

class PartyMainViewController: UIViewController {
    
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
    
    @IBAction func play(sender: AnyObject) {
        playSong()
    }
    
    @IBAction func pause(sender: AnyObject) {
        pauseSong()
    }
    
    var userIsHost = true
    var audioPlayerHasAudioToPlay = false
    var audioPlayerIsPlaying = false

    var audioPlayer: AVAudioPlayer?
    var audioSession: AVAudioSession?
    var songProgressTimer: NSTimer?
    
    override func viewDidLoad() {
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "audioPlayerInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)
        
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
        
        hideMessages()
        setPartyInfoHidden(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController.visibleViewController.title = "Party"
        refresh()
        
        // Refresh stuff (temporarily doing this here while the server is down)
        self.hideMessages()
        self.setPartyInfoHidden(false)
        self.setAudioPlayerButtonsForPlaying(true)
        
        SCClient.sharedClient.downloadSoundCloudSongData(143553285,
            completion: { data, response in
                var errorPtr = NSErrorPointer()
                self.audioPlayer = AVAudioPlayer(data: data, error: errorPtr)
                if !errorPtr {
                    dispatchAsyncToMainQueue(
                        action: {
                            println("no error")
                            self.audioPlayerHasAudioToPlay = true
                            self.playSong()
                        }
                    )
                } else {
                    println("there was an error")
                    println("ERROR: \(errorPtr)")
                }
            }
        )
        
        SCClient.sharedClient.getSoundCloudSongByID(143553285,
            success: {data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let SCSongName = responseJSON["title"].string
                let SCUserName = responseJSON["user"]["username"].string
                let SCSongDuration = responseJSON["duration"].integer
                var SCArtworkURL = responseJSON["artwork_url"].string
                if SCArtworkURL != nil {
                    SCArtworkURL = SCArtworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                    downloadImageWithURLString(SCArtworkURL!,
                        { success, image in
                            if success {
                                self.songImage!.image = image
                            } else {
                                self.songImage!.backgroundColor = UIColor.orange()
                            }
                        }
                    )
                } else {
                    self.songImage!.backgroundColor = UIColor.red()
                }
                println("\(SCSongName)   \(SCUserName)   \(SCArtworkURL)")
                self.songNameLabel!.text = SCSongName!
                self.songArtistLabel!.text = SCUserName
                self.songTimeLabel!.text = timeInMillisecondsToFormattedMinSecondTimeLabelString(SCSongDuration!)
                
            },
            failure: defaultAFHTTPFailureBlock
        )
        
        /*
        SCClient.sharedClient.searchSoundCloudForSongWithString("summer",
            success: {data, responseObject in
                let responseJSON = JSONValue(responseObject)
                //println(responseJSON)
                let songsArray = responseJSON.array
                println(songsArray![0])
                println(songsArray!.count)
            },
            failure: defaultAFHTTPFailureBlock
        )*/
    }
    
    func playSong() {
        println("playSong")
        if (audioSession != nil) {
            var setCategoryError = NSErrorPointer()
            var success1 = audioSession!.setCategory(AVAudioSessionCategoryPlayback, error: setCategoryError)
            if !success1 {
                println("not successful 1")
                if setCategoryError {
                    println("ERROR with set category")
                    println(setCategoryError)
                }
            }
            
            var activationError = NSErrorPointer()
            var success2 = audioSession!.setActive(true, error: activationError)
            if !success2 {
                println("not successful 2")
                if activationError {
                    println("ERROR with set active")
                    println(activationError)
                }
            }
            
            if audioPlayer != nil && success1 && success2 {
                if audioPlayerHasAudioToPlay {
                    audioPlayer!.play()
                    audioPlayerIsPlaying = true
                    setAudioPlayerButtonsForPlaying(true)
                    
                    // Start the timer to be updating songProgress
                    songTimerShouldBeActive(true)
                } else {
                    let alert = UIAlertView(title: "No Songs To Play", message: "Please add some songs to play, then press play again", delegate: nil, cancelButtonTitle: "Ok")
                    alert.show()
                }
            } else {
                let alert = UIAlertView(title: "Audio Session Problem", message: "Unable to setup an active audio session for audio playback. Double check nothing is overriding audio from One Sound, then refresh the party. If that doesn't work then restart the app", delegate: nil, cancelButtonTitle: "Ok")
                alert.show()
            }
        } else {
            println("ERROR no audio session")
        }
    }
    
    func pauseSong() {
        println("pauseSong")
        if audioSession != nil && audioPlayer != nil && audioPlayerHasAudioToPlay && audioPlayerIsPlaying {
            audioPlayer!.pause()
            audioPlayerIsPlaying = false
            setAudioPlayerButtonsForPlaying(false)
            
            // Stop the timer from updating songProgress
            songTimerShouldBeActive(false)
        }
    }
    
    func updateSongProgress(timer: NSTimer!) {
        if audioPlayer != nil && audioPlayerHasAudioToPlay {
            let progress = Float(audioPlayer!.currentTime / audioPlayer!.duration)
            songProgress!.progress = progress
        } else {
            songProgress!.progress = 0.0
        }
    }
    
    func songTimerShouldBeActive(shouldBeActive: Bool) {
        if shouldBeActive {
            if songProgressTimer == nil {
                songProgressTimer = NSTimer.scheduledTimerWithTimeInterval(0.33, target: self, selector: "updateSongProgress:", userInfo: nil, repeats: true)
            }
        } else {
            if songProgressTimer != nil {
                songProgressTimer!.invalidate()
            }
            songProgressTimer = nil
        }
    }
    
    // Copy pasta'd from Profile view controller to have the same kind of refresh logic
    // Keeping the commented out things for now to show what kind of changes were made for that
    // TODO: update the refresh to remove comments irrelevant to this controller when finished w/ it
    func refresh() {
        // Returns true if refreshed with a valid user
        println("refreshing PartyMainViewController")
        
        // Ensure audio session is initialized when the user is the host
        if userIsHost && audioSession == nil {
            audioSession = AVAudioSession.sharedInstance()
        }
        
        // Ensure the audio player is available when the user is the host
        if userIsHost && audioPlayer == nil {
            audioPlayer = AVAudioPlayer()
        }
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                LocalParty.sharedParty.joinAndOrRefreshParty(1,
                    JSONUpdateCompletion: {
                        if LocalParty.sharedParty.setup == true {
                            // Actually refresh stuff
                            self.hideMessages()
                            self.setPartyInfoHidden(false)
                            self.setAudioPlayerButtonsForPlaying(true)
                        } else {
                            self.showMessages("Well, this is awkward", detailLine: "We're not really sure what happened, try refreshing the party!")
                            self.setPartyInfoHidden(true)
                        }
                    }, failureAddOn: {
                        self.setPartyInfoHidden(true)
                        self.showMessages("Unable to load party", detailLine: "Please connect to the internet and refresh the party")
                    }
                )
            } else {
                //setUserInfoHidden(true)
                //setStoriesTableToHidden(true)
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart One Sound")
                self.setPartyInfoHidden(true)
                //disableButtons()
            }
        } else {
            //setUserInfoHidden(true)
            //setStoriesTableToHidden(true)
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use One Sound")
            self.setPartyInfoHidden(true)
            //disableButtons()
        }
    }
    
    func setPartyInfoHidden(hidden: Bool) {
        songImage!.hidden = hidden
        soundcloudLogo!.hidden = hidden
        songNameLabel!.hidden = hidden
        songArtistLabel!.hidden = hidden
        songTimeLabel!.hidden = hidden
        
        // Only set button visibility for hiding; to show them the player must be checked
        // When hiding the party info, reset the song labels to empty and the song progress to 0
        if hidden == true {
            playButton!.hidden = hidden
            playButton!.alpha = 0.0
            pauseButton!.hidden = hidden
            pauseButton!.alpha = 0.0
            songProgress!.hidden = hidden
            songProgress!.alpha = 0.0
            songProgress!.progress = 0.0
            
            songNameLabel!.text = ""
            songArtistLabel!.text = ""
            songTimeLabel!.text = ""
        }
    }
    
    func setAudioPlayerButtonsForPlaying(audioPlayerIsPlaying: Bool) {
        // The sog progress should always be visible when there's an audio player
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
                self.pauseButton!.hidden = false
                self.pauseButton!.alpha = 1.0
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
}

extension PartyMainViewController {
    // MARK: handling AVAudioSession notifications
    func audioPlayerInterruption(n: NSNotification) {
        println("AVAudioSessionInterruptionNotification")
        if userIsHost {
            let userInfo = n.userInfo as NSDictionary
            let interruptionType = userInfo[AVAudioSessionInterruptionTypeKey] as UInt
            switch interruptionType {
            case AVAudioSessionInterruptionType.Began.toRaw():
                println("interruption began")
                // TODO: respond to began interruption
                /* apples example
                if (playing) {
                    playing = NO;
                    interruptedOnPlayback = YES;
                    [self updateUserInterface];
                }
                */
            case AVAudioSessionInterruptionType.Ended.toRaw():
                println("interruption ended")
                // TODO: respond to ended interruption
                /* apples example
                if (interruptedOnPlayback) {
                    [player prepareToPlay];
                    [player play];
                    playing = YES;
                    interruptedOnPlayback = NO;
                }
                */
            default:
                println("ERROR interruption type was neither began or ended")
            }
        }
    }
    
    // TODO: "Responding to a Media Server Reset"
    // Apple says it's rare but can happen; do this when the app is baically done?
}
