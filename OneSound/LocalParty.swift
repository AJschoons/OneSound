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
    func setSongImageForNoSongHidden(shouldBeHidden: Bool)
}

enum PartyStrictnessOption: Int {
    case Off = 0
    case Low = 1
    case Default = 2
    case Strict = 3
    
    func PartyStrictnessOptionToString() -> String {
        switch self {
        case .Off:
            return "Off"
        case .Low:
            return "Low"
        case .Default:
            return "Default"
        case .Strict:
            return "Strict"
        }
    }
}

let LocalPartySongInformationDidChangeNotification = "LocalPartySongInformationDidChange"
let LocalPartyMemberInformationDidChangeNotification = "LocalPartyMemberInformationDidChange"

class LocalParty: NSObject {
    
    var delegate: LocalPartyDelegate!
    
    var partyID: Int!
    var isPrivate: Bool!
    var hostUserID: Int?
    var name: String!
    var strictness: Int!
    
    var songs = [Song]()
    var members = [User]()
    var currentSong: Song?
    var songCache = [Int : NSData]()
    
    var setup = false
    
    var audioPlayer: AVAudioPlayer?
    var audioSession: AVAudioSession?
    var songProgressTimer: NSTimer?
    var partyRefreshTimer: NSTimer!
    
    var userIsHost = false
    var audioPlayerHasAudioToPlay = false
    var audioPlayerIsPlaying = false
    var playingSongID: Int?
    
    var shouldTryAnotherRefresh = true
    
    class var sharedParty: LocalParty {
    struct Static {
        static let localParty = LocalParty()
        }
        return Static.localParty
    }
    
    override init() {
        super.init()
        
        partyRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
        
        // Should help the AVAudioPlayer move to the next song when in background?
        // http://stackoverflow.com/questions/9660488/ios-avaudioplayer-doesnt-continue-to-next-song-while-in-background
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "audioPlayerInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)
        
        // Refresh the party info when the user info changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshForUserInfoChange", name: LocalUserInformationDidChangeNotification, object: nil)
        
        audioSession = AVAudioSession.sharedInstance()
        audioPlayer = AVAudioPlayer()
        
        var setCategoryError = NSErrorPointer()
        var success1 = audioSession!.setCategory(AVAudioSessionCategoryPlayback, error: setCategoryError)
        if !success1 {
            println("not successful 1")
            if setCategoryError != nil {
                println("ERROR with set category")
                println(setCategoryError)
            }
        }
    }
    
    func refreshForUserInfoChange() {
        setup = false
        refresh()
    }
    
    func refresh() {
        println("refreshing LocalParty")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                if LocalUser.sharedUser.party != nil {
                    if setup == true {
                        // Party is actually setup
                        println("party is setup")
                        delegate.hideMessages()
                        delegate.setPartyInfoHidden(false)
                        
                        if userIsHost {
                            if audioPlayerHasAudioToPlay == false {
                                
                            }
                        } else {
                            updateCurrentSong(LocalUser.sharedUser.party!,
                                completion: {
                                    println("audioPlayerIsPlaying (in refresh): \(self.audioPlayerIsPlaying)")
                                    
                                    if self.audioPlayerIsPlaying {
                                        self.delegate.setAudioPlayerButtonsForPlaying(true)
                                        println("party audio is playing, no need to change anything")
                                    } else {
                                        if self.playingSongID == nil || self.playingSongID != 143553285 {
                                            // Need to get the song and update info
                                            println("need to get the song and update info")
                                            // TODO: check for upcoming songs
                                            // TODO: add image that says to add a song
                                            
                                            SongStore.sharedStore.songAudioForKey(143553285, completion: {
                                                song in
                                                if song != nil {
                                                    println("song was not nil")
                                                    var errorPtr = NSErrorPointer()
                                                    self.audioPlayer = AVAudioPlayer(data: song!, error: errorPtr)
                                                    println("*** SONG IS \(((Double(song!.length) / 1024.0) / 1024.0)) Mb ***")
                                                    
                                                    if errorPtr == nil {
                                                        println("no error")
                                                        self.updateDelegateSongInformation(143553285)
                                                        self.playingSongID = 143553285
                                                        self.audioPlayerHasAudioToPlay = true
                                                        self.delegate.setAudioPlayerButtonsForPlaying(false)
                                                    } else {
                                                        println("there was an error")
                                                        println("ERROR: \(errorPtr)")
                                                        self.delegate.showMessages("Well, this is awkward", detailLine: "The song could not be played, please try adding another")
                                                        self.delegate.setPartyInfoHidden(true)
                                                    }
                                                } else {
                                                    println("song WAS nil")
                                                    // TODO: check for the next available song
                                                    self.delegate.showMessages("Well, this is awkward", detailLine: "The song was unavailable for download, please try adding another")
                                                    self.delegate.setPartyInfoHidden(true)
                                                }
                                                }
                                            )
                                            
                                        } else {
                                            // Don't need to get the song info
                                            self.delegate.setAudioPlayerButtonsForPlaying(false)
                                            println("don't need to get the song audio")
                                        }
                                    }
                                }, noCurrentSong: {
                                    self.delegate.setSongImageForNoSongHidden(false)
                                }, failureAddOn: {
                                    self.delegate.setPartyInfoHidden(true)
                                    self.delegate.showMessages("Unable to load current song", detailLine: "Please check internet connection and refresh the party")
                                }
                            )
                        }
                    } else {
                        if shouldTryAnotherRefresh {
                            shouldTryAnotherRefresh = false
                            // If the party is valid but not setup, try joining it and then refreshing it once more
                            joinParty(LocalUser.sharedUser.party!,
                                JSONUpdateCompletion: {
                                    // TODO: find a better way to accomplish this
                                    self.shouldTryAnotherRefresh = true
                                    self.refresh()
                                }, failureAddOn: {
                                    self.refresh()
                                }
                            )
                        } else {
                            delegate.showMessages("Well, this is awkward", detailLine: "We're not really sure what happened, try refreshing the party!")
                            delegate.setPartyInfoHidden(true)
                        }
                    }
                } else {
                    delegate.showMessages("Not member of a party", detailLine: "Become a party member by joining or creating a party")
                    delegate.setPartyInfoHidden(true)
                }
            } else {
                //setUserInfoHidden(true)
                //setStoriesTableToHidden(true)
                delegate.showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart One Sound")
                delegate.setPartyInfoHidden(true)
                //disableButtons()
            }
        } else {
            //setUserInfoHidden(true)
            //setStoriesTableToHidden(true)
            delegate.showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use One Sound")
            delegate.setPartyInfoHidden(true)
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
                if setCategoryError != nil {
                    println("ERROR with set category")
                    println(setCategoryError)
                }
            }
            
            var activationError = NSErrorPointer()
            success2 = audioSession!.setActive(true, error: activationError)
            if !success2 {
                println("not successful 2")
                if activationError != nil {
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
    func updateCurrentSong(pid: Int, completion: completionClosure? = nil, noCurrentSong: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        OSAPI.sharedClient.GETCurrentSong(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                self.currentSong = Song(json: responseJSON)
                SongStore.sharedStore.songInformationForSong(self.currentSong!,
                    completion: { song in
                        if completion != nil {
                            completion!()
                        }
                    }, failureAddOn: failureAddOn)
            }, failure: { task, error in
                var shouldDoDefaultFailureBlock = true
                
                if let response = task.response as? NSHTTPURLResponse {
                    println("errorResponseCode:\(response.statusCode)")
                    if response.statusCode == 404 && noCurrentSong != nil {
                        shouldDoDefaultFailureBlock = false
                        noCurrentSong!()
                    }
                    
                }
                
                if shouldDoDefaultFailureBlock == true {
                    if failureAddOn != nil {
                        failureAddOn!()
                    }
                    defaultAFHTTPFailureBlock!(task: task, error: error)
                }
            }
        )
    }
    
    func joinParty(pid: Int, JSONUpdateCompletion: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        let user = LocalUser.sharedUser
        OSAPI.sharedClient.GETParty(pid, userID: user.id, userAPIToken: user.apiToken,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                //println(responseJSON)
                
                self.updateMainPartyInfoFromJSON(responseJSON, JSONUpdateCompletion)
                self.updatePartyMembers(pid)
                self.updatePartySongs(pid)
            }, failure: { task, error in
                if failureAddOn != nil {
                    failureAddOn!()
                }
                defaultAFHTTPFailureBlock!(task: task, error: error)
            }
        )
    }
    
    func updateDelegateSongInformation(id: Int) {
        SCClient.sharedClient.getSoundCloudSongByID(id,
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
    
    func updatePartySongs(pid: Int, completion: completionClosure? = nil) {
        OSAPI.sharedClient.GETPartyPlaylist(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                self.updatePartySongInfoFromJSON(responseJSON)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updatePartyMembers(pid: Int, completion: completionClosure? = nil) {
        OSAPI.sharedClient.GETPartyMembers(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                self.updatePartyMembersInfoFromJSON(responseJSON)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    func createNewParty(partyName: String, partyPrivacy: Bool, partyStrictness: Int, respondToChangeAttempt: (Bool) -> (), failure: AFHTTPFailureBlock = defaultAFHTTPFailureBlockForSigningIn) {
        let user = LocalUser.sharedUser
        
        OSAPI.sharedClient.POSTParty(partyName, partyPrivacy: partyPrivacy, partyStrictness: partyStrictness, userID: user.id, userAPIToken: user.apiToken,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    // Update new party information
                    let pid = responseJSON["pid"].integer
                    self.joinParty(pid!,
                        JSONUpdateCompletion: {
                            respondToChangeAttempt(true)
                            LocalUser.sharedUser.party = pid
                        }, failureAddOn: {
                            respondToChangeAttempt(false)
                        }
                    )
                } else {
                    // Server didn't accept request for new party with supplied information
                    respondToChangeAttempt(false)
                }
            }, failure: defaultAFHTTPFailureBlock)
    }
    
    func updatePartyMembersInfoFromJSON(json: JSONValue, completion: completionClosure? = nil) {
        var newMembersArray = [User]()
        
        var membersArray = json.array
        if membersArray != nil {
            for user in membersArray! {
                newMembersArray.append(User(json: user))
            }
            members = newMembersArray
        }
        
        if completion != nil {
            completion!()
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(LocalPartySongInformationDidChangeNotification, object: nil)
        
        println("UPDATED PARTY WITH \(self.members.count) MEMBERS")
    }
    
    func updatePartySongInfoFromJSON(json: JSONValue, completion: completionClosure? = nil) {
        var newSongsArray = [Song]()
        
        var songsArray = json.array
        if songsArray != nil {
            for song in songsArray! {
                newSongsArray.append(Song(json: song))
            }
            songs = newSongsArray
        }
        
        if completion != nil {
            completion!()
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(LocalPartySongInformationDidChangeNotification, object: nil)
        
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
        
        if hostUserID == LocalUser.sharedUser.id {
            userIsHost == true
            println("*** USER IS HOST ***")
        } else {
            userIsHost == false
        }
    
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
            // TODO: figure out a way around this error
            /*
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
            */
        }
    }
    
    // TODO: "Responding to a Media Server Reset"
    // Apple says it's rare but can happen; do this when the app is baically done?
}
