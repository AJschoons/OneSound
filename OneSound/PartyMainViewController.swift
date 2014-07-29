//
//  PartyMainViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit
import AVFoundation

class PartyMainViewController: UIViewController {
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    
    @IBOutlet weak var volumeControl: UISlider?
    
    @IBAction func play(sender: AnyObject) {
        audioPlayer!.play()
    }
    
    @IBAction func stop(sender: AnyObject) {
        audioPlayer!.stop()
    }
    
    @IBAction func adjustVolume(sender: AnyObject) {
        audioPlayer!.volume = volumeControl!.value
        println(volumeControl!.value)
    }
    
    var audioPlayer: AVAudioPlayer? = AVAudioPlayer()
    
    override func viewDidLoad() {
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
        
        hideMessages()
        refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController.visibleViewController.title = "Party"
        refresh()
        
        SCClient.sharedClient.downloadSoundCloudSongData(143553285,
            completion: { data, response in
                var errorPtr = NSErrorPointer()
                self.audioPlayer = AVAudioPlayer(data: data, error: errorPtr)
                if !errorPtr {
                    println("no error")
                    self.audioPlayer!.play()
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
            },
            failure: defaultAFHTTPFailureBlock
        )
        
        SCClient.sharedClient.searchSoundCloudForSongWithString("summer",
            success: {data, responseObject in
                let responseJSON = JSONValue(responseObject)
                //println(responseJSON)
                let songsArray = responseJSON.array
                println(songsArray![0])
                println(songsArray!.count)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    // Copy pasta'd from Profile view controller to have the same kind of refresh logic
    // Keeping the commented out things for now to show what kind of changes were made for that
    // TODO: update the refresh to remove comments irrelevant to this controller when finished w/ it
    func refresh() -> Bool {
        // Returns true if refreshed with a valid user
        var validUser = false
        println("refreshing PartyMainViewController")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                validUser = true
                hideMessages()
                LocalParty.sharedParty.joinAndOrRefreshParty(1)
            } else {
                //setUserInfoHidden(true)
                //setStoriesTableToHidden(true)
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart One Sound")
                //disableButtons()
            }
        } else {
            //setUserInfoHidden(true)
            //setStoriesTableToHidden(true)
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use One Sound")
            //disableButtons()
        }
        
        return validUser
    }
    
    func showMessages(mainLine: String?, detailLine: String?) {
        if mainLine {
            messageLabel1!.alpha = 1
            messageLabel1!.text = mainLine
        }
        if detailLine {
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
