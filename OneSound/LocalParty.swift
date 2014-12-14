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
    func showPartySongInfo()
    func showMessages(mainLine: String?, detailLine: String?)
    func hideMessages()
    func setPartySongInfo(# songName: String, songArtist: String, songTime: String, user: User?)
    func setPartySongImage(# songToPlay: Bool, artworkToShow: Bool, loadingSong: Bool, image: UIImage?)
    func clearSongInfo()
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

class LocalParty: NSObject {
    
    let songImageCache = (UIApplication.sharedApplication().delegate as AppDelegate).songImageCache
    
    var delegate: LocalPartyDelegate!
    
    var partyID: Int!
    var isPrivate: Bool!
    var hostUserID: Int?
    var name: String!
    var strictness: Int!
    
    var songs = [Song]()
    var members = [User]()
    var currentSong: Song?
    var currentUser: User?
    var songCache = [Int : NSData]()
    
    var setup = false
    
    var audioPlayer: AVAudioPlayer?
    var audioSession: AVAudioSession?
    var songProgressTimer: NSTimer?
    var partyRefreshTimer: NSTimer!
    var recentNextSongCallTimer: NSTimer?
    
    var currentSongImage: UIImage?
    
    var userIsHost = false
    var audioPlayerHasAudioToPlay = false
    var audioPlayerIsPlaying = false
    var recentlyGotNextSong = false
    var audioIsDownloading = false
    
    var shouldTryAnotherRefresh = true
    
    class var sharedParty: LocalParty {
    struct Static {
        static let localParty = LocalParty()
        }
        return Static.localParty
    }
    
    override init() {
        super.init()
        
        partyRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(15, target: self, selector: "refresh", userInfo: nil, repeats: true)
        
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
    
    func disallowGetNextSongCallTemporarily() {
        recentlyGotNextSong = true
        NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "allowGetNextSongCall", userInfo: nil, repeats: false)
    }
    
    func allowGetNextSongCall() {
        recentlyGotNextSong = false
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
                        dispatchAsyncToMainQueue(action: {
                            self.delegate.hideMessages()
                            self.delegate.setPartyInfoHidden(false)
                        })
                        println("user is host: \(userIsHost)")
                        
                        if userIsHost {
                            if !audioPlayerHasAudioToPlay && !audioIsDownloading && !recentlyGotNextSong {
                                dispatchAsyncToMainQueue(action: {
                                    self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: false, image: nil)
                                })
                                disallowGetNextSongCallTemporarily()
                                getNextSongForDelegate()
                            } else if !audioPlayerHasAudioToPlay && audioIsDownloading {
                                dispatchAsyncToMainQueue(action: {
                                    self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: true, image: nil)
                                })
                            } else {
                                updateDelegateSongInformation()
                            }
                        } else {
                            updateCurrentSong(LocalUser.sharedUser.party!,
                                completion: {
                                    println("audioPlayerIsPlaying (in refresh): \(self.audioPlayerIsPlaying)")
                                    
                                    if self.audioPlayerIsPlaying {
                                        dispatchAsyncToMainQueue(action: {
                                            self.delegate.setAudioPlayerButtonsForPlaying(true)
                                        })
                                        println("party audio is playing, no need to change anything")
                                    } else {
                                        /*
                                        if self.playingSongID == nil || self.playingSongID != 143553285 {
                                            // Need to get the song and update info
                                            println("need to get the song and update info")
                                            // TODO: check for upcoming songs
                                            // TODO: add image that says to add a song
                                            /*
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
                                            */
                                            
                                        } else {
                                            // Don't need to get the song info
                                            self.delegate.setAudioPlayerButtonsForPlaying(false)
                                            println("don't need to get the song audio")
                                        }
                                        */
                                    }
                                }, noCurrentSong: {
                                    dispatchAsyncToMainQueue(action: {
                                        self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: false, image: nil)
                                    })
                                }, failureAddOn: {
                                    dispatchAsyncToMainQueue(action: {
                                        self.delegate.setPartyInfoHidden(true)
                                        self.delegate.showMessages("Unable to load current song", detailLine: "Please check internet connection and refresh the party")
                                    })
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
                            dispatchAsyncToMainQueue(action: {
                                self.delegate.showMessages("Well, this is awkward", detailLine: "We're not really sure what happened, try refreshing the party!")
                                self.delegate.setPartyInfoHidden(true)
                            })
                        }
                    }
                } else {
                    dispatchAsyncToMainQueue(action: {
                        self.delegate.showMessages("Not member of a party", detailLine: "Become a party member by joining or creating a party")
                        self.delegate.setPartyInfoHidden(true)
                    })
                }
            } else {
                //setUserInfoHidden(true)
                //setStoriesTableToHidden(true)
                dispatchAsyncToMainQueue(action: {
                    self.delegate.showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
                    self.delegate.setPartyInfoHidden(true)
                })
                //disableButtons()
            }
        } else {
            //setUserInfoHidden(true)
            //setStoriesTableToHidden(true)
            dispatchAsyncToMainQueue(action: {
                self.delegate.showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
                self.delegate.setPartyInfoHidden(true)
            })
            //disableButtons()
        }
    }
    
    func getNextSongForDelegate() {
        getNextSong(LocalUser.sharedUser.party!,
            completion: {
                self.audioIsDownloading = true
                dispatchAsyncToMainQueue(action: {
                    self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: true, image: nil)
                })
                SongStore.sharedStore.songAudioForKey(self.currentSong!.externalID,
                    completion: { songData in
                        self.setDelegatePreparedToPlaySong(songData)
                    }
                )
            }, noCurrentSong: {
                self.audioIsDownloading = false
                dispatchAsyncToMainQueue(action: {
                    self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: false, image: nil)
                    self.delegate.setPartySongInfo(songName: "", songArtist: "", songTime: "", user: nil)
                })
            }, failureAddOn: {
                self.audioIsDownloading = false
                dispatchAsyncToMainQueue(action: {
                    self.delegate.setPartySongInfo(songName: "", songArtist: "", songTime: "", user: nil)
                    self.delegate.setPartyInfoHidden(true)
                    self.delegate.showMessages("Unable to load current song", detailLine: "Please check internet connection and refresh the party")
                })
            }
        )
    }
    
    func setDelegatePreparedToPlaySong(songData: NSData?) {
        audioIsDownloading = false
        //delegate.setPartySongImageOverlayHidden(true, withImage: nil)
        
        if songData != nil {
            println("song was not nil")
            
            var errorPtr = NSErrorPointer()
            self.audioPlayer = AVAudioPlayer(data: songData!, error: errorPtr)
            
            if errorPtr == nil {
                println("no error")
                self.audioPlayer!.delegate = self
                println("*** SONG IS \(((Double(songData!.length) / 1024.0) / 1024.0)) MB ***")
                self.updateDelegateSongInformation()
                //self.playingSongID = self.currentSong!.externalID
                dispatchAsyncToMainQueue(action: {
                    self.delegate.setAudioPlayerButtonsForPlaying(true)
                })
                //self.delegate.showPartySongInfo()
                self.audioPlayerHasAudioToPlay = true
                self.playSong()
            } else {
                println("there was an error")
                println("ERROR: \(errorPtr)")
                dispatchAsyncToMainQueue(action: {
                    self.delegate.showMessages("Well, this is awkward", detailLine: "The song could not be played, please try adding another")
                    self.delegate.setPartyInfoHidden(true)
                })
            }
        } else {
            println("song WAS nil")
            // TODO: check for the next available song
            dispatchAsyncToMainQueue(action: {
                self.delegate.showMessages("Well, this is awkward", detailLine: "The song was unavailable for download, please try adding another")
                self.delegate.setPartyInfoHidden(true)
            })
        }
    }
    
    func playSong() {
        println("playSong")
        var success1 = true
        var success2 = true
        
        if !userIsHost {
            return
        }
        
        // Ensure audio session is initialized when the user is the host
        if audioSession == nil {
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
        if audioPlayer == nil {
            audioPlayer = AVAudioPlayer()
        }
        
        println("audioSession:\(audioSession != nil) audioPlayer:\(audioPlayer != nil) audioToPlay:\(audioPlayerHasAudioToPlay) audioPlaying:\(audioPlayerIsPlaying)")
            
        if audioPlayer != nil && success1 && success2 {
            if audioPlayerHasAudioToPlay {
                if !audioPlayerIsPlaying {
                    audioPlayer!.play()
                    audioPlayerIsPlaying = true
                    println("audioPlayerIsPlaying: \(audioPlayerIsPlaying)")
                    dispatchAsyncToMainQueue(action: {
                        self.delegate.setAudioPlayerButtonsForPlaying(true)
                        // Start the timer to be updating songProgress
                        self.songTimerShouldBeActive(true)
                    })
                }
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
        println("audioSession:\(audioSession != nil) audioPlayer:\(audioPlayer != nil) audioToPlay:\(audioPlayerHasAudioToPlay) playing:\(audioPlayerIsPlaying)")
        if audioSession != nil && audioPlayer != nil && audioPlayerHasAudioToPlay && audioPlayerIsPlaying {
            audioPlayer!.pause()
            audioPlayerIsPlaying = false
            dispatchAsyncToMainQueue(action: {
                self.delegate.setAudioPlayerButtonsForPlaying(false)
                // Stop the timer from updating songProgress
                self.songTimerShouldBeActive(false)
            })
        }
    }
    
    func updateSongProgress(timer: NSTimer!) {
        if audioPlayer != nil && audioPlayerHasAudioToPlay {
            let progress = Float(audioPlayer!.currentTime / audioPlayer!.duration)
            dispatchAsyncToMainQueue(action: {
                self.delegate.updateSongProgress(progress)
            })
        } else {
            dispatchAsyncToMainQueue(action: {
                self.delegate.updateSongProgress(0.0)
            })
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
    
    func updateDelegateSongInformation() {
        if currentSong != nil {
            dispatchAsyncToMainQueue(action: {
                self.delegate.showPartySongInfo()
                self.delegate.setPartySongInfo(songName: self.currentSong!.name, songArtist: self.currentSong!.artistName, songTime: timeInSecondsToFormattedMinSecondTimeLabelString(self.currentSong!.duration), user: self.currentUser!)
            })
            updateDelegateSongImage() // UI calls in this fxn use dispatchAsyncToMainQueue
        }
    }
    
    func updateDelegateSongImage() {
        if currentSong!.artworkURL != nil {
            let largerArtworkURL = currentSong!.artworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
            
            songImageCache.queryDiskCacheForKey(largerArtworkURL,
                done: { image, imageCacheType in
                    if image != nil {
                        dispatchAsyncToMainQueue(action: {
                            self.delegate.setPartySongImage(songToPlay: true, artworkToShow: true, loadingSong: false, image: image)
                        })
                    } else {
                        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: largerArtworkURL), options: nil, progress: nil,
                            completed: { image, error, cacheType, boolValue, url in
                                if error == nil && image != nil {
                                    self.songImageCache.storeImage(image, forKey: largerArtworkURL)
                                    dispatchAsyncToMainQueue(action: {
                                        self.delegate.setPartySongImage(songToPlay: true, artworkToShow: true, loadingSong: false, image: image)
                                    })
                                } else {
                                    dispatchAsyncToMainQueue(action: {
                                        self.delegate.setPartySongImage(songToPlay: true, artworkToShow: false, loadingSong: false, image: nil)
                                    })
                                }
                            }
                        )
                    }
                }
            )
        } else {
            dispatchAsyncToMainQueue(action: {
                self.delegate.setPartySongImage(songToPlay: true, artworkToShow: false, loadingSong: false, image: nil)
            })
        }
    }
    
    func clearSongInfo() {
        currentSong = nil
        currentUser = nil
        currentSongImage = nil
        
        dispatchAsyncToMainQueue(action: {
            self.delegate.clearSongInfo()
        })
    }
    
    func resetAllPartyInfo() {
        audioPlayer = nil
        audioSession = nil
        clearSongInfo()
        
        partyID = -1
        isPrivate = false
        hostUserID = -1
        name = ""
        strictness = -1
        
        songs = [Song]()
        members = [User]()
        currentSong = nil
        currentUser = nil
        songCache = [Int : NSData]()
        
        setup = false

        songProgressTimer = nil
        recentNextSongCallTimer = nil
        
        userIsHost = false
        audioPlayerHasAudioToPlay = false
        audioPlayerIsPlaying = false
        recentlyGotNextSong = false
        audioIsDownloading = false
        shouldTryAnotherRefresh = true
        
        dispatchAsyncToMainQueue(action: {
            self.delegate.setPartyInfoHidden(true)
        })
    }
}

extension LocalParty {
    // MARK: Party networking related code for user's active party
    
    func getNextSong(pid: Int, completion: completionClosure? = nil, noCurrentSong: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        
        let localUser = LocalUser.sharedUser
        OSAPI.sharedClient.GETNextSong(pid, userID: localUser.id, userAPIToken: localUser.apiToken,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                self.currentUser = User(json: responseJSON["user"])
                self.currentSong = Song(json: responseJSON)
                if completion != nil {
                    completion!()
                }
            }, failure: { task, error in
                var shouldDoDefaultFailureBlock = true
                
                if let response = task.response as? NSHTTPURLResponse {
                    println("errorResponseCode:\(response.statusCode)")
                    if response.statusCode == 404 && noCurrentSong != nil {
                        shouldDoDefaultFailureBlock = false
                        if noCurrentSong != nil {
                            noCurrentSong!()
                        }
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
    
    func updateCurrentSong(pid: Int, completion: completionClosure? = nil, noCurrentSong: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        OSAPI.sharedClient.GETCurrentSong(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                self.currentSong = Song(json: responseJSON)
                if completion != nil {
                    completion!()
                }
            }, failure: { task, error in
                var shouldDoDefaultFailureBlock = true
                
                if let response = task.response as? NSHTTPURLResponse {
                    println("errorResponseCode:\(response.statusCode)")
                    if response.statusCode == 404 && noCurrentSong != nil {
                        shouldDoDefaultFailureBlock = false
                        if noCurrentSong != nil {
                            noCurrentSong!()
                        }
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
        // Makes it so none of the old info stays if you join a party from an old one
        resetAllPartyInfo()
        
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

    func updatePartySongs(pid: Int, completion: completionClosure? = nil) {
        OSAPI.sharedClient.GETPartyPlaylist(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                self.updatePartySongInfoFromJSON(responseJSON, completion: completion)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updatePartyMembers(pid: Int, completion: completionClosure? = nil) {
        OSAPI.sharedClient.GETPartyMembers(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                self.updatePartyMembersInfoFromJSON(responseJSON, completion: completion)
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
        
        println("UPDATED PARTY WITH \(self.songs.count) SONGS")
    }
    
    func updateMainPartyInfoFromJSON(json: JSONValue, completion: completionClosure? = nil) {
        setup = true
        
        println(json)
        
        partyID = json["pid"].integer
        isPrivate = json["privacy"].bool
        hostUserID = json["host"].integer
        name = json["name"].string
        strictness = json["strictness"].integer
        
        if hostUserID == LocalUser.sharedUser.id {
            userIsHost = true
            println("*** USER IS HOST ***")
        } else {
            userIsHost == false
        }
    
        if completion != nil {
            completion!()
        }
    }
}

extension LocalParty: AVAudioPlayerDelegate {
    // MARK: respond to audio playback ENDING (interruptions are handled by avaudio session)
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        audioPlayerIsPlaying = false
        audioPlayerHasAudioToPlay = false
        clearSongInfo()
        disallowGetNextSongCallTemporarily()
        getNextSongForDelegate()
    }
}

extension LocalParty {
    // MARK: handling AVAudioSession notifications
    // TODO: handle audio session interruptions
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
