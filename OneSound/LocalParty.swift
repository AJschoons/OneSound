//
//  LocalParty.swift
//  OneSound
//
//  Created by adam on 7/28/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit
import AVFoundation

protocol LocalPartyDelegate {
    func updateSongProgress(progress: Float)
    func setAudioPlayerButtonsForPlaying(audioPlayerIsPlaying: Bool)
    func setPartyInfoHidden(hidden: Bool)
    func showMessages(mainLine: String?, detailLine: String?)
    func hideMessages()
    func setPartySongInfo(songName: String, songArtist: String, songTime: String)
    func setPartySongImage(image: UIImage?, backgroundColor: UIColor?)
}

class LocalParty: NSObject {
    
    var delegate: LocalPartyDelegate!
    
    var partyID: Int!
    var isPrivate: Bool!
    var hostUserID: Int?
    var name: String!
    var strictness: Int!
    
    var songs = [Song?]()
    
    var setup = false
    
    var audioPlayer: AVAudioPlayer?
    var audioSession: AVAudioSession?
    var songProgressTimer: NSTimer?
    var partyRefreshTimer: NSTimer!
    
    var userIsHost = true
    var audioPlayerHasAudioToPlay = false
    var audioPlayerIsPlaying = false
    
    var songCache = [Int : NSData]()
    
    class var sharedParty: LocalParty {
    struct Static {
        static let localParty = LocalParty()
        }
        return Static.localParty
    }
    
    var numOfTimesToSetStuff = 1
    
    override init() {
        super.init()
        
        partyRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "refresh", userInfo: nil, repeats: true)
        
        // Should help the AVAudioPlayer move to the next song when in background?
        // http://stackoverflow.com/questions/9660488/ios-avaudioplayer-doesnt-continue-to-next-song-while-in-background
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "audioPlayerInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)
        
        audioSession = AVAudioSession.sharedInstance()
        audioPlayer = AVAudioPlayer()
        
        var setCategoryError = NSErrorPointer()
        var success1 = audioSession!.setCategory(AVAudioSessionCategoryPlayback, error: setCategoryError)
        if !success1 {
            println("not successful 1")
            if setCategoryError {
                println("ERROR with set category")
                println(setCategoryError)
            }
        }
    }
    
    func refresh() {
        println("refreshing LocalParty")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                joinAndOrRefreshParty(1,
                    JSONUpdateCompletion: {
                        if self.setup == true {
                            // Actually refresh stuff
                            self.delegate.hideMessages()
                            self.delegate.setPartyInfoHidden(false)
                            
                            println("audioPlayerIsPlaying (in refresh): \(self.audioPlayerIsPlaying)")
                            
                            if self.audioPlayerIsPlaying {
                                self.delegate.setAudioPlayerButtonsForPlaying(false)
                            } else {
                                if self.numOfTimesToSetStuff > 0 {
                                    self.numOfTimesToSetStuff -= 1
                                    
                                    // Need to download next song ASAP...?
                                    SCClient.sharedClient.downloadSoundCloudSongData(143553285,
                                        completion: { data, response in
                                            var errorPtr = NSErrorPointer()
                                            println("*** SONG IS \(((Double(data.length) / 1024.0) / 1024.0)) Mb ***")
                                            dispatchAsyncToMainQueue(
                                                action: {
                                                    self.audioPlayer = AVAudioPlayer(data: data, error: errorPtr)
                                                    if !errorPtr {
                                                        println("no error")
                                                        self.audioPlayerHasAudioToPlay = true
                                                        //self.playSong()
                                                        self.delegate.setAudioPlayerButtonsForPlaying(false)
                                                    } else {
                                                        println("there was an error")
                                                        println("ERROR: \(errorPtr)")
                                                        self.delegate.setAudioPlayerButtonsForPlaying(false)
                                                    }
                                                }
                                            )
                                        }
                                    )
                                    
                                    SCClient.sharedClient.getSoundCloudSongByID(143553285,
                                        success: {data, responseObject in
                                            let responseJSON = JSONValue(responseObject)
                                            //println(responseJSON)
                                            let SCSongName = responseJSON["title"].string
                                            let SCUserName = responseJSON["user"]["username"].string
                                            let SCSongDuration = responseJSON["duration"].integer
                                            var SCArtworkURL = responseJSON["artwork_url"].string
                                            if SCArtworkURL != nil {
                                                SCArtworkURL = SCArtworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                                                downloadImageWithURLString(SCArtworkURL!,
                                                    { success, image in
                                                        if success {
                                                            self.delegate.setPartySongImage(image, backgroundColor: nil)
                                                        } else {
                                                            self.delegate.setPartySongImage(nil, backgroundColor: UIColor.orange())
                                                        }
                                                    }
                                                )
                                            } else {
                                                self.delegate.setPartySongImage(nil, backgroundColor: UIColor.red())
                                            }
                                            println("\(SCSongName)   \(SCUserName)   \(SCArtworkURL)")
                                            self.delegate.setPartySongInfo(SCSongName!, songArtist: SCUserName!, songTime: timeInMillisecondsToFormattedMinSecondTimeLabelString(SCSongDuration!))
                                        },
                                        failure: defaultAFHTTPFailureBlock
                                    )
                                }
                            }
                        } else {
                            self.delegate.showMessages("Well, this is awkward", detailLine: "We're not really sure what happened, try refreshing the party!")
                            self.delegate.setPartyInfoHidden(true)
                        }
                    }, failureAddOn: {
                        self.delegate.setPartyInfoHidden(true)
                        self.delegate.showMessages("Unable to load party", detailLine: "Please connect to the internet and refresh the party")
                    }
                )
            } else {
                //setUserInfoHidden(true)
                //setStoriesTableToHidden(true)
                self.delegate.showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart One Sound")
                delegate.setPartyInfoHidden(true)
                //disableButtons()
            }
        } else {
            //setUserInfoHidden(true)
            //setStoriesTableToHidden(true)
            self.delegate.showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use One Sound")
            self.delegate.setPartyInfoHidden(true)
            //disableButtons()
        }
    }
    
    func playSong() {
        println("playSong")
        
        var success1 = true
        var success2 = true
        
        // Ensure audio session is initialized when the user is the host
        if userIsHost && audioSession == nil {
            audioSession = AVAudioSession.sharedInstance()
            
            var setCategoryError = NSErrorPointer()
            success1 = audioSession!.setCategory(AVAudioSessionCategoryPlayback, error: setCategoryError)
            if !success1 {
                println("not successful 1")
                if setCategoryError {
                    println("ERROR with set category")
                    println(setCategoryError)
                }
            }
            
            var activationError = NSErrorPointer()
            success2 = audioSession!.setActive(true, error: activationError)
            if !success2 {
                println("not successful 2")
                if activationError {
                    println("ERROR with set active")
                    println(activationError)
                }
            }
        }
        
        // Ensure the audio player is available when the user is the host
        if userIsHost && audioPlayer == nil {
            audioPlayer = AVAudioPlayer()
        }
            
        if audioPlayer != nil && success1 && success2 {
            if audioPlayerHasAudioToPlay {
                if !audioPlayerIsPlaying {
                    audioPlayer!.play()
                    audioPlayerIsPlaying = true
                    println("audioPlayerIsPlaying: \(audioPlayerIsPlaying)")
                    delegate.setAudioPlayerButtonsForPlaying(true)
                }
                
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
    }
    
    func pauseSong() {
        println("pauseSong")
        if audioSession != nil && audioPlayer != nil && audioPlayerHasAudioToPlay && audioPlayerIsPlaying {
            audioPlayer!.pause()
            audioPlayerIsPlaying = false
            delegate.setAudioPlayerButtonsForPlaying(false)
            
            // Stop the timer from updating songProgress
            songTimerShouldBeActive(false)
        }
    }
    
    func updateSongProgress(timer: NSTimer!) {
        if audioPlayer != nil && audioPlayerHasAudioToPlay {
            let progress = Float(audioPlayer!.currentTime / audioPlayer!.duration)
            delegate.updateSongProgress(progress)
        } else {
            delegate.updateSongProgress(0.0)
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
}

extension LocalParty {
    // MARK: Party networking related code for user's active party
    
    func joinAndOrRefreshParty(pid: Int, JSONUpdateCompletion: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        let user = LocalUser.sharedUser
        OSAPI.sharedClient.GETParty(pid, userID: user.id, userAPIToken: user.apiToken,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                //println(responseJSON)
                
                self.updateMainPartyInfoFromJSON(responseJSON, JSONUpdateCompletion)
                self.updatePartyMembers(pid)
                self.updatePartySongs(pid)
            },
            failure: { task, error in
                if failureAddOn != nil {
                    failureAddOn!()
                }
                defaultAFHTTPFailureBlock!(task: task, error: error)
            }
        )
    }
    
    func updatePartySongs(pid: Int) {
        OSAPI.sharedClient.GETPartyPlaylist(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                self.updatePartySongInfoFromJSON(responseJSON)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updatePartyMembers(pid: Int) {
        OSAPI.sharedClient.GETPartyMembers(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                //println(responseJSON)
                //self.updatePartySongInfoFromJSON(responseJSON)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    /*
    func updatePartyMembersInfoFromJSON(json: JSONValue) {
        .removeAll(keepCapacity: true)
        var songsToGet = true
        var i = 1
        while songsToGet {
            if let songDict = json["\(i)"].object {
                self.songs.insert(Song(json: json), atIndex: (i-1))
                i++
            } else {
                songsToGet = false
            }
        }
        println("UPDATED PARTY WITH \(self.songs.count) SONGS")
    }*/
    
    func updatePartySongInfoFromJSON(json: JSONValue) {
        songs.removeAll(keepCapacity: true)
        var songsArray = json.array
        if songsArray != nil {
            for song in songsArray! {
                songs.append(Song(json: song))
            }
        }
        /*
        while songsToGet {
            if let songDict = json["\(i)"].object {
                self.songs.insert(Song(json: json), atIndex: (i-1))
                i++
            } else {
                songsToGet = false
            }
        }
        */
        println("UPDATED PARTY WITH \(self.songs.count) SONGS")
    }
    
    func updateMainPartyInfoFromJSON(json: JSONValue, completion: completionClosure? = nil) {
        setup = true
        
        partyID = json["pid"].integer
        isPrivate = json["privacy"].bool
        hostUserID = json["host"].integer
        name = json["name"].string
        strictness = json["strictness"].integer
    
        if completion != nil {
            completion!()
        }
    }
}

extension LocalParty {
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
