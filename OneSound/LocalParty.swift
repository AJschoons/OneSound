//
//  LocalParty.swift
//  OneSound
//
//  Created by adam on 7/28/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

protocol LocalPartyDelegate {
    func updateSongProgress(progress: Float)
    func setAudioPlayerButtonsForPlaying(audioPlayerIsPlaying: Bool)
    func setPartyInfoHidden(hidden: Bool)
    func showPartySongInfo()
    func showMessages(mainLine: String?, detailLine: String?)
    func hideMessages()
    func setPartySongInfo(# songName: String, songArtist: String, songTime: String, user: User?, thumbsUp: Bool, thumbsDown: Bool)
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
    var queueSong: Song?
    var queueUser: User?
    
    var setup = false
    
    var audioPlayer: STKAudioPlayer!
    var audioSession: AVAudioSession!
    
    var songPlayingTimer: NSTimer?
    var partyRefreshTimer: NSTimer!
    var recentNextSongCallTimer: NSTimer?
    
    var currentSongImage: UIImage?
    
    var userIsHost = false
    var audioPlayerHasAudioToPlay = false
    var audioPlayerIsPlaying = false
    var recentlyGotNextSong = false
    var audioIsDownloading = false
    var attemptedToQueueSongForThisSong = false
    
    var shouldTryAnotherRefresh = true
    
    class var sharedParty: LocalParty {
    struct Static {
        static let localParty = LocalParty()
        }
        return Static.localParty
    }
    
    override init() {
        super.init()
        
        partyRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "onPartyRefreshTimer", userInfo: nil, repeats: true)
        
        // Should help the AVAudioPlayer move to the next song when in background?
        // http://stackoverflow.com/questions/9660488/ios-avaudioplayer-doesnt-continue-to-next-song-while-in-background
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "audioPlayerInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)
        
        // Refresh the party info when the user info changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshForUserInfoChange", name: LocalUserInformationDidChangeNotification, object: nil)
        
        // Setup audio session
        audioSession = AVAudioSession.sharedInstance()
        
        var setBufferDurationError = NSErrorPointer()
        var success1 = audioSession.setPreferredIOBufferDuration(0.1, error: setBufferDurationError)
        if !success1 {
            println("not successful 1")
            if setBufferDurationError != nil {
                println("ERROR with set buffer")
                println(setBufferDurationError)
            }
        }
        
        var setCategoryError = NSErrorPointer()
        var success2 = audioSession!.setCategory(AVAudioSessionCategoryPlayback, error: setCategoryError)
        if !success2 {
            println("not successful 2")
            if setCategoryError != nil {
                println("ERROR with set category")
                println(setCategoryError)
            }
        }
        
        // Setup audio player
        let equalizerB:(Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32) = (50, 100, 200, 400, 800, 600, 2600, 16000, 0, 0, 0, 0, 0, 0 , 0, 0, 0, 0, 0, 0, 0, 0 , 0, 0 )
        var optns:STKAudioPlayerOptions = STKAudioPlayerOptions(flushQueueOnSeek: true, enableVolumeMixer: true, equalizerBandFrequencies:equalizerB,readBufferSize: (64 * 1024), bufferSizeInSeconds: 10, secondsRequiredToStartPlaying: 1, gracePeriodAfterSeekInSeconds: 0.5, secondsRequiredToStartPlayingAfterBufferUnderun: 7.5)
        
        audioPlayer = STKAudioPlayer(options: optns)
        audioPlayer.meteringEnabled = true
        audioPlayer.volume = 1
        audioPlayer.delegate = self
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
    
    func onPartyRefreshTimer() {
        if userIsHost { refresh() }
    }
    
    func refresh() {
        println("refreshing LocalParty")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                if LocalUser.sharedUser.party != nil {
                    if setup == true {
                        setDelegatePartyInfoVisible()
                        
                        if userIsHost {
                            refreshForHost()
                        } else {
                            refreshForNonHost()
                        }
                    } else {
                        attemptToJoinPartyOneMoreTime()
                    }
                } else {
                    // Party was nil, not member of a party
                    dispatchAsyncToMainQueue(action: {
                        self.delegate.showMessages("Not member of a party", detailLine: "Become a party member by joining or creating a party")
                        self.delegate.setPartyInfoHidden(true)
                    })
                }
            } else {
                // User not setup, not signed into full or guest account
                dispatchAsyncToMainQueue(action: {
                    self.delegate.showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
                    self.delegate.setPartyInfoHidden(true)
                })
            }
        } else {
            // Not connected to the internet
            dispatchAsyncToMainQueue(action: {
                self.delegate.showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
                self.delegate.setPartyInfoHidden(true)
            })
        }
    }
    
    func refreshForHost() {
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
    }
    
    func refreshForNonHost() {
        updateCurrentSongForDelegate()
    }
    
    func setDelegatePartyInfoVisible() {
        // Party is actually setup
        println("party is setup")
        dispatchAsyncToMainQueue(action: {
            self.delegate.hideMessages()
            self.delegate.setPartyInfoHidden(false)
        })
        println("user is host: \(userIsHost)")
    }
    
    func attemptToJoinPartyOneMoreTime() {
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
    
    // To be used for non-hosts
    func updateCurrentSongForDelegate() {
        updateCurrentSong(partyID,
            completion: {
                self.updateDelegateSongInformation()
            },
            noCurrentSong: {
                dispatchAsyncToMainQueue(action: {
                    self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: false, image: nil)
                    self.delegate.setPartySongInfo(songName: "", songArtist: "", songTime: "", user: nil, thumbsUp: false, thumbsDown: false)
                })
            },
            failureAddOn: {
                dispatchAsyncToMainQueue(action: {
                    self.delegate.setPartySongInfo(songName: "", songArtist: "", songTime: "", user: nil, thumbsUp: false, thumbsDown: false)
                    self.delegate.setPartyInfoHidden(true)
                    self.delegate.showMessages("Unable to load current song", detailLine: "Please check internet connection and refresh the party")
                })
            }
        )
    }
    
    // Only to be used for hosts
    func getNextSongForDelegate() {
        
        getNextSong(partyID,
            completion: { song, user in
                //self.audioIsDownloading = true
                //dispatchAsyncToMainQueue(action: {
                //    self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: true, image: nil)
                //})
                self.currentSong = song
                self.currentUser = user
                self.setDelegatePreparedToPlaySong(SCClient.sharedClient.getSongURLString(self.currentSong!.externalID))
            }, noCurrentSong: {
                self.audioIsDownloading = false
                dispatchAsyncToMainQueue(action: {
                    self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: false, image: nil)
                    self.delegate.setPartySongInfo(songName: "", songArtist: "", songTime: "", user: nil, thumbsUp: false, thumbsDown: false)
                })
            }, failureAddOn: {
                self.audioIsDownloading = false
                dispatchAsyncToMainQueue(action: {
                    self.delegate.setPartySongInfo(songName: "", songArtist: "", songTime: "", user: nil, thumbsUp: false, thumbsDown: false)
                    self.delegate.setPartyInfoHidden(true)
                    self.delegate.showMessages("Unable to load current song", detailLine: "Please check internet connection and refresh the party")
                })
            }
        )
    }
    
    // Only to be used for hosts
    func queueNextSongForDelegate() {
        attemptedToQueueSongForThisSong = true
        
        getNextSong(partyID,
            completion: { song, user in
                self.queueSong = song
                self.queueUser = user
                self.audioPlayer.queue(SCClient.sharedClient.getSongURLString(song.externalID))
            }, noCurrentSong: {
                
            }, failureAddOn: {
                
            }
        )
    }
    
    // Move queue song info to current song info, clear the queue info after
    func setQueueSongAndUserToCurrent() -> Bool {
        if queueSong != nil && queueUser != nil {
            currentSong = queueSong
            currentUser = queueUser
            
            queueSong = nil
            queueUser = nil
            return true
        }
        
        return false
    }
    
    func setDelegatePreparedToPlaySong(songURLString: String) {
        audioIsDownloading = false
        
        updateDelegateSongInformation()
        updateMPNowPlayingInfoCenterInfo()
        
        dispatchAsyncToMainQueue(action: {
            self.delegate.setAudioPlayerButtonsForPlaying(true)
        })
        
        audioPlayerHasAudioToPlay = true
        audioPlayer.play(songURLString)
        playSong()
    }
    
    func setDelegatePreparedToPlaySongFromQueue() {
        audioIsDownloading = false
        audioPlayerHasAudioToPlay = true
        
        updateDelegateSongInformation()
        updateMPNowPlayingInfoCenterInfo()
        
        dispatchAsyncToMainQueue(action: {
            self.delegate.setAudioPlayerButtonsForPlaying(true)
        })
    }
    
    func playSong() {
        println("playSong")
        if !userIsHost {
            return
        }
        
        // Ensure audio session is initialized when the user is the host
        let audioSessionSetup = setupAudioSessionForHostPlaying()
        
        
        println("audioSession:\(audioSession != nil) audioPlayer:\(audioPlayer != nil) audioToPlay:\(audioPlayerHasAudioToPlay) audioPlaying:\(audioPlayerIsPlaying)")
            
        if audioSessionSetup {
            if audioPlayerHasAudioToPlay {
                if !audioPlayerIsPlaying {
                    audioPlayer!.resume()
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
            let alert = UIAlertView(title: "Audio Session Problem", message: "Unable to setup an active audio session for audio playback. Double check nothing is overriding audio from OneSound, then refresh the party. If that doesn't work then restart the app", delegate: nil, cancelButtonTitle: "Ok")
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
    
    func onSongPlayingTimer(timer: NSTimer!) {
        if audioPlayer != nil && audioPlayerHasAudioToPlay {
            let progress = audioPlayer!.progress
            let duration = audioPlayer!.duration
            
            if duration < 0.000001 {
                // "in between" songs; duration is 0
                delegate.updateSongProgress(0.0)
            } else {
                let progressPercent = Float(progress / duration)
                dispatchAsyncToMainQueue(action: {
                    self.delegate.updateSongProgress(progressPercent)
                })
                
                // Try queueing the next song
                let timeRemaining = duration - progress
                if timeRemaining < 5 && !attemptedToQueueSongForThisSong {
                    queueNextSongForDelegate()
                }
            }
        } else {
            dispatchAsyncToMainQueue(action: {
                self.delegate.updateSongProgress(0.0)
            })
        }
    }
    
    func songTimerShouldBeActive(shouldBeActive: Bool) {
        if shouldBeActive {
            if songPlayingTimer == nil {
                songPlayingTimer = NSTimer.scheduledTimerWithTimeInterval(0.33, target: self, selector: "onSongPlayingTimer:", userInfo: nil, repeats: true)
            }
        } else {
            if songPlayingTimer != nil {
                songPlayingTimer!.invalidate()
            }
            songPlayingTimer = nil
        }
    }
    
    func updateDelegateSongInformation() {
        if currentSong != nil {
            
            var thumbsUp = false
            var thumbsDown = false
            
            if currentSong!.userVote != nil {
                switch currentSong!.userVote! {
                case .Up:
                    thumbsUp = true
                case .Down:
                    thumbsDown = true
                default:
                    break
                }
            }
            
            dispatchAsyncToMainQueue(action: {
                self.delegate.showPartySongInfo()
                self.delegate.setPartySongInfo(songName: self.currentSong!.name, songArtist: self.currentSong!.artistName, songTime: timeInSecondsToFormattedMinSecondTimeLabelString(self.currentSong!.duration), user: self.currentUser!, thumbsUp: thumbsUp, thumbsDown: thumbsDown)
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
    
    // Make sure to use this AFTER updateDelegateSongImage() and updateDelegateSongInformation()
    func updateMPNowPlayingInfoCenterInfo() {
        
        if currentSong!.artworkURL != nil {
            let largerArtworkURL = currentSong!.artworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
            songImageCache.queryDiskCacheForKey(largerArtworkURL,
                done: { image, imageCacheType in
                    if image != nil {
                        let artwork = MPMediaItemArtwork(image: image)
                        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : self.currentSong!.artistName,  MPMediaItemPropertyTitle : self.currentSong!.name, MPMediaItemPropertyArtwork : artwork, MPMediaItemPropertyPlaybackDuration : self.currentSong!.duration]
                    } else {
                        let artwork = MPMediaItemArtwork(image: songImageForNoSongArtwork)
                        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : self.currentSong!.artistName,  MPMediaItemPropertyTitle : self.currentSong!.name, MPMediaItemPropertyArtwork : artwork, MPMediaItemPropertyPlaybackDuration : self.currentSong!.duration]
                    }
                }
            )
        } else {
            let artwork = MPMediaItemArtwork(image: songImageForNoSongArtwork)
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : currentSong!.artistName,  MPMediaItemPropertyTitle : currentSong!.name, MPMediaItemPropertyArtwork : artwork, MPMediaItemPropertyPlaybackDuration : currentSong!.duration]
        }
    }
    
    func setupAudioSessionForHostPlaying() -> Bool {
        if audioSession == nil {
            audioSession = AVAudioSession.sharedInstance()
        }
        
        var setBufferDurationError = NSErrorPointer()
        var success1 = audioSession.setPreferredIOBufferDuration(0.1, error: setBufferDurationError)
        if !success1 {
            println("not successful 1")
            if setBufferDurationError != nil {
                println("ERROR with set buffer")
                println(setBufferDurationError)
            }
        }
        
        var setCategoryError = NSErrorPointer()
        var success2 = audioSession!.setCategory(AVAudioSessionCategoryPlayback, error: setCategoryError)
        if !success2 {
            println("not successful 2")
            if setCategoryError != nil {
                println("ERROR with set category")
                println(setCategoryError)
            }
        }
        
        var activationError = NSErrorPointer()
        var success3 = audioSession!.setActive(true, error: activationError)
        if !success3 {
            println("not successful 3")
            if activationError != nil {
                println("ERROR with set active")
                println(activationError)
            }
        }
        
        return success1 && success2 && success3
    }
    
    func clearSongInfo() {
        currentSong = nil
        currentUser = nil
        currentSongImage = nil
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = ["" : ""]
        
        dispatchAsyncToMainQueue(action: {
            self.delegate.clearSongInfo()
        })
    }
    
    func resetAllPartyInfo() {
        // Clears current and queued songs
        audioPlayer.stop()
        
        clearSongInfo()
        
        partyID = -1
        isPrivate = false
        hostUserID = -1
        name = ""
        strictness = -1
        
        songs = []
        members = []
        currentSong = nil
        currentUser = nil
        queueSong = nil
        queueUser = nil
        
        setup = false

        songPlayingTimer = nil
        recentNextSongCallTimer = nil
        
        userIsHost = false
        audioPlayerHasAudioToPlay = false
        audioPlayerIsPlaying = false
        recentlyGotNextSong = false
        audioIsDownloading = false
        shouldTryAnotherRefresh = true
        attemptedToQueueSongForThisSong = false
        
        dispatchAsyncToMainQueue(action: {
            self.delegate.setPartyInfoHidden(true)
        })
    }
}

extension LocalParty {
    // MARK: Party networking related code for user's active party
    
    func getNextSong(pid: Int, completion: ((song: Song, user: User) -> ())? = nil, noCurrentSong: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        
        let localUser = LocalUser.sharedUser
        OSAPI.sharedClient.GETNextSong(pid, userID: localUser.id, userAPIToken: localUser.apiToken,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                
                if completion != nil {
                    completion!(song: Song(json: responseJSON), user: User(json: responseJSON["user"]))
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
                println(responseJSON)
                self.currentSong = Song(json: responseJSON)
                self.currentUser = User(json: responseJSON["user"])
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
                
                LocalUser.sharedUser.party = pid
                
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

extension LocalParty {
    // MARK: Party networking related code for song voting
    
    func songUpvote(sid: Int) {
        let user = LocalUser.sharedUser
        OSAPI.sharedClient.POSTSongUpvote(sid, userID: user.id, userAPIToken: user.apiToken, success: nil, failure: defaultAFHTTPFailureBlock)
    }
    
    func songDownvote(sid: Int) {
        let user = LocalUser.sharedUser
        OSAPI.sharedClient.POSTSongDownvote(sid, userID: user.id, userAPIToken: user.apiToken, success: nil, failure: defaultAFHTTPFailureBlock)
    }
    
    func songClearVote(sid: Int) {
        let user = LocalUser.sharedUser
        OSAPI.sharedClient.DELETESongVote(sid, userID: user.id, userAPIToken: user.apiToken, success: nil, failure: defaultAFHTTPFailureBlock)
    }
}

extension LocalParty: STKAudioPlayerDelegate {
    // Raised when an item has started playing
    func audioPlayer(audioPlayer: STKAudioPlayer!, didStartPlayingQueueItemId queueItemId: NSObject!) {
        
    }
    
    // Raised when an item has finished buffering (may or may not be the currently playing item)
    // This event may be raised multiple times for the same item if seek is invoked on the player
    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject!) {
        
    }

    // Raised when the state of the player has changed
    func audioPlayer(audioPlayer: STKAudioPlayer!, stateChanged state: STKAudioPlayerState, previousState:STKAudioPlayerState) {
        
    }
    
    // Raised when an item has finished playing
    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishPlayingQueueItemId queueItemId: NSObject!, withReason stopReason:STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        
        if setQueueSongAndUserToCurrent() {
            // If there's a queued song
            audioPlayerIsPlaying = false
            audioPlayerHasAudioToPlay = false
            setDelegatePreparedToPlaySongFromQueue()
        } else {
            audioPlayerIsPlaying = false
            audioPlayerHasAudioToPlay = false
            clearSongInfo()
            disallowGetNextSongCallTemporarily()
            getNextSongForDelegate()
        }
    }
    
    // Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
    func audioPlayer(audioPlayer: STKAudioPlayer!, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        
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
