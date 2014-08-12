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
        LocalParty.sharedParty.playSong()
    }
    
    @IBAction func pause(sender: AnyObject) {
        LocalParty.sharedParty.pauseSong()
    }
    
    override func viewDidLoad() {
        // This is the delegate to the LocalParty
        LocalParty.sharedParty.delegate = self
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        
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
        
        /*
        SCClient.sharedClient.searchSoundCloudForSongWithString("summer",
            success: {data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let songsArray = responseJSON.array
                //println(songsArray!)
                println(songsArray!.count)
            },
            failure: defaultAFHTTPFailureBlock
        )
        */
    }
    
    func updateSongProgress(progress: Float) {
        songProgress!.progress = progress
    }
    
    func refresh() {
        //println("refreshing PartyMainViewController")
        if LocalParty.sharedParty.setup == false {
            LocalParty.sharedParty.refresh()
        }
    }
    
    func setPartySongInfo(songName: String, songArtist: String, songTime: String) {
        songNameLabel!.text = songName
        songArtistLabel!.text = songArtist
        songTimeLabel!.text = songTime
    }
    
    func setPartySongImage(image: UIImage?, backgroundColor: UIColor?) {
        if image != nil {
            songImage!.image = image
        }
        
        if backgroundColor != nil {
            songImage!.backgroundColor = backgroundColor
            songImage!.image = nil
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

extension PartyMainViewController: LocalPartyDelegate {
    
}