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
    func setPartySongInfo(# name: String, artist: String, time: String)
    func setPartySongUserInfo(user: User?, thumbsUp: Bool, thumbsDown: Bool)
    func setPartySongImage(# songToPlay: Bool, artworkToShow: Bool, loadingSong: Bool, image: UIImage?)
    func clearAllSongInfo()
    func setPartyMainVCRightBarButton(# create: Bool, leave: Bool, settings: Bool)
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
    
    let playlistManager = PartyPlaylistManager()
    
    var partyID: Int!
    var isPrivate: Bool!
    var hostUserID: Int?
    var name: String!
    var strictness: Int!
    
    //var songs = [Song]()
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
    
    var userIsHost = false
    var audioPlayerHasAudioToPlay = false
    var audioPlayerIsPlaying = false
    var recentlyGotNextSong = false
    var audioIsDownloading = false
    var attemptedToQueueSongForThisSong = false
    
    var shouldTryAnotherRefresh = true
    
    var numOnSongPlayingTimerTicks = 0
    
    class var sharedParty: LocalParty {
    struct Static {
        static let localParty = LocalParty()
        }
        return Static.localParty
    }
    
    override init() {
        super.init()
        
        partyRefreshTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "onPartyRefreshTimer", userInfo: nil, repeats: true)
        
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
        NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "allowGetNextSongCall", userInfo: nil, repeats: false)
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
        
        let user = LocalUser.sharedUser
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                if LocalUser.sharedUser.party != nil && LocalUser.sharedUser.party != 0 {
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
                        self.delegate.setPartyMainVCRightBarButton(create: true, leave: false, settings: false)
                        self.delegate.setPartyInfoHidden(true)
                    })
                }
            } else {
                // User not setup, not signed into full or guest account
                dispatchAsyncToMainQueue(action: {
                    self.delegate.showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
                    self.delegate.setPartyMainVCRightBarButton(create: false, leave: false, settings: false)
                    self.delegate.setPartyInfoHidden(true)
                })
            }
        } else {
            // Not connected to the internet
            dispatchAsyncToMainQueue(action: {
                self.delegate.showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
                self.delegate.setPartyMainVCRightBarButton(create: false, leave: false, settings: false)
                self.delegate.setPartyInfoHidden(true)
            })
        }
    }
    
    func refreshForHost() {
        dispatchAsyncToMainQueue(action: {
            self.delegate.setPartyMainVCRightBarButton(create: false, leave: false, settings: true)
        })
        
        if !audioPlayerHasAudioToPlay && !audioIsDownloading && !recentlyGotNextSong {
            dispatchAsyncToMainQueue(action: {
                self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: false, image: nil)
            })
            getNextSongForDelegate()
        } else if !audioPlayerHasAudioToPlay && audioIsDownloading {
            dispatchAsyncToMainQueue(action: {
                self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: true, image: nil)
            })
        } else {
            updateCurrentSongAndUserThenDelegate(onlyUpdateCurrentUserInfo: true)
        }
    }
    
    func refreshForNonHost() {
        dispatchAsyncToMainQueue(action: {
            self.delegate.setPartyMainVCRightBarButton(create: false, leave: true, settings: false)
        })
        
        updateCurrentSongAndUserThenDelegate()
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
    
    // Get and update the current song and user, then reflect that update in the delegate
    func updateCurrentSongAndUserThenDelegate(onlyUpdateCurrentUserInfo: Bool = false) {
        updateCurrentSongAndUser(partyID,
            completion: {
                self.updateDelegateSongAndUserInformation(onlyUpdateCurrentUserInfo: onlyUpdateCurrentUserInfo)
            },
            noCurrentSong: {
                dispatchAsyncToMainQueue(action: {
                    self.delegate.clearAllSongInfo()
                })
            },
            failureAddOn: {
                dispatchAsyncToMainQueue(action: {
                    self.delegate.clearAllSongInfo()
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
                    self.delegate.clearAllSongInfo()
                })
            }, failureAddOn: {
                self.audioIsDownloading = false
                dispatchAsyncToMainQueue(action: {
                    self.delegate.clearAllSongInfo()
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
        
        updateDelegateSongAndUserInformation()
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
        
        updateDelegateSongAndUserInformation()
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
                    
                    // Receive remote control events
                    UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
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
        if audioSession != nil && audioPlayerHasAudioToPlay && audioPlayerIsPlaying {
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
        if audioPlayerHasAudioToPlay {
            let progress = audioPlayer.progress
            let duration = audioPlayer.duration
            
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
                
                // Refresh the MPNowPlayingInfo every 3 ticks (~1 second)
                if numOnSongPlayingTimerTicks < 3 {
                    ++numOnSongPlayingTimerTicks
                } else {
                    numOnSongPlayingTimerTicks = 0
                    updateMPNowPlayingInfoCenterInfo(elapsedTime: progress)
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
    
    func updateDelegateSongAndUserInformation(onlyUpdateCurrentUserInfo: Bool = false) {
        if currentSong != nil && currentUser != nil {
            
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
                self.delegate.setPartySongUserInfo(self.currentUser!, thumbsUp: thumbsUp, thumbsDown: thumbsDown)
                
                if !onlyUpdateCurrentUserInfo {
                    self.delegate.setPartySongInfo(name: self.currentSong!.name, artist: self.currentSong!.artistName, time: timeInSecondsToFormattedMinSecondTimeLabelString(self.currentSong!.duration))
                }
            })
            
            if !onlyUpdateCurrentUserInfo {
                updateDelegateSongImage() // UI calls in this fxn use dispatchAsyncToMainQueue
            }
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
    func updateMPNowPlayingInfoCenterInfo(elapsedTime: Double = 0) {
        if currentSong != nil {
            if currentSong!.artworkURL != nil {
                let largerArtworkURL = currentSong!.artworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                songImageCache.queryDiskCacheForKey(largerArtworkURL,
                    done: { image, imageCacheType in
                        if image != nil {
                            let artwork = MPMediaItemArtwork(image: image)
                            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : self.currentSong!.artistName,  MPMediaItemPropertyTitle : self.currentSong!.name, MPMediaItemPropertyArtwork : artwork, MPMediaItemPropertyPlaybackDuration : self.currentSong!.duration, MPNowPlayingInfoPropertyElapsedPlaybackTime : elapsedTime]
                        } else {
                            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : self.currentSong!.artistName,  MPMediaItemPropertyTitle : self.currentSong!.name, MPMediaItemPropertyPlaybackDuration : self.currentSong!.duration, MPNowPlayingInfoPropertyElapsedPlaybackTime : elapsedTime]
                            
                        }
                    }
                )
            } else {
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : currentSong!.artistName,  MPMediaItemPropertyTitle : currentSong!.name, MPMediaItemPropertyPlaybackDuration : currentSong!.duration, MPNowPlayingInfoPropertyElapsedPlaybackTime : elapsedTime]
                
            }
        } else {
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = ["" : ""]
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
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = ["" : ""]
        
        dispatchAsyncToMainQueue(action: {
            self.delegate.clearAllSongInfo()
        })
    }
    
    func resetAllPartyInfo() {
        // Clears current and queued songs
        audioPlayer.stop()
        
        clearSongInfo()
        
        LocalUser.sharedUser.party = nil
        partyID = 0
        isPrivate = false
        hostUserID = 0
        name = ""
        strictness = 0
        
        playlistManager.reset()
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
        let shouldAttempt = !recentlyGotNextSong
        disallowGetNextSongCallTemporarily()
        
        if partyID != 0 && partyID != nil && shouldAttempt {
            let localUser = LocalUser.sharedUser
            OSAPI.sharedClient.GETNextSong(pid,
                success: { data, responseObject in
                    let responseJSON = JSONValue(responseObject)
                    println(responseJSON)
                    
                    if completion != nil {
                        completion!(song: Song(json: responseJSON), user: User(json: responseJSON["user"]))
                    }
                },
                failure: { task, error in
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
    }
    
    func updateCurrentSongAndUser(pid: Int, completion: completionClosure? = nil, noCurrentSong: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        
        if partyID != 0 && partyID != nil {
            OSAPI.sharedClient.GETCurrentSong(pid,
                success: { data, responseObject in
                    let responseJSON = JSONValue(responseObject)
                    println(responseJSON)
                    
                    self.currentSong = Song(json: responseJSON)
                    self.currentUser = User(json: responseJSON["user"])
                    
                    if completion != nil {
                        completion!()
                    }
                },
                failure: { task, error in
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
    }
    
    func joinParty(pid: Int, JSONUpdateCompletion: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        // Makes it so none of the old info stays when joining a party from an old one
        resetAllPartyInfo()
        
        if pid != 0 {
            let user = LocalUser.sharedUser
            OSAPI.sharedClient.GETParty(pid,
                success: { data, responseObject in
                    let responseJSON = JSONValue(responseObject)
                    //println(responseJSON)
                    
                    LocalUser.sharedUser.party = pid
                    
                    self.updateMainPartyInfoFromJSON(responseJSON, JSONUpdateCompletion)
                    self.updatePartyMembers(pid)
                }, failure: { task, error in
                    if failureAddOn != nil {
                        failureAddOn!()
                    }
                    defaultAFHTTPFailureBlock!(task: task, error: error)
                }
            )
        } else {
            println("ERROR: trying to join a party with pid = 0")
        }
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
    
    func createNewParty(name: String, privacy: Bool, strictness: Int, respondToChangeAttempt: (Bool) -> (), failure: AFHTTPFailureBlock = defaultAFHTTPFailureBlockForSigningIn) {
        let user = LocalUser.sharedUser
        
        OSAPI.sharedClient.POSTParty(name, privacy: privacy, strictness: strictness,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    // Update new party information
                    let pid = responseJSON["pid"].integer
                    self.joinParty(pid!,
                        JSONUpdateCompletion: {
                            LocalUser.sharedUser.party = pid
                            respondToChangeAttempt(true)
                        }, failureAddOn: {
                            respondToChangeAttempt(false)
                        }
                    )
                } else {
                    // Server didn't accept request for new party with supplied information
                    respondToChangeAttempt(false)
                }
            }, failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updatePartyInfo(name: String, privacy: Bool, strictness: Int, respondToChangeAttempt: (Bool) -> (), failure: AFHTTPFailureBlock = defaultAFHTTPFailureBlockForSigningIn) {
        let user = LocalUser.sharedUser
        
        OSAPI.sharedClient.PUTParty(partyID, name: name, privacy: privacy, strictness: strictness,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let status = responseJSON["status"].string
                
                // TODO: probably don't need to join party after updating
                // Could just update the info from the arguments provided
                if status == "success" {
                    // Update/get new party information
                    self.joinParty(self.partyID,
                        JSONUpdateCompletion: {
                            respondToChangeAttempt(true)
                        }, failureAddOn: {
                            respondToChangeAttempt(false)
                        }
                    )
                } else {
                    // Server didn't accept request for new party with supplied information
                    respondToChangeAttempt(false)
                }
            }, failure: defaultAFHTTPFailureBlock
        )
    }
    
    // Leaves a party. If successful, clears the party info. respondToChangeAttempt = true if left party, else false
    func leaveParty(# respondToChangeAttempt: (Bool) -> ()) {
        let user = LocalUser.sharedUser
        OSAPI.sharedClient.DELETEUserParty(user.id,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    // Clear all party information
                    self.resetAllPartyInfo()
                    respondToChangeAttempt(true)
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
        OSAPI.sharedClient.POSTSongUpvote(sid, success: nil, failure: defaultAFHTTPFailureBlock)
    }
    
    func songDownvote(sid: Int) {
        let user = LocalUser.sharedUser
        OSAPI.sharedClient.POSTSongDownvote(sid, success: nil, failure: defaultAFHTTPFailureBlock)
    }
    
    func songClearVote(sid: Int) {
        let user = LocalUser.sharedUser
        OSAPI.sharedClient.DELETESongVote(sid, success: nil, failure: defaultAFHTTPFailureBlock)
    }
}

extension LocalParty: STKAudioPlayerDelegate {
    // MARK: STKAudioPlayer delegate methods
    
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
            setDelegatePreparedToPlaySongFromQueue()
        } else {
            audioPlayerIsPlaying = false
            audioPlayerHasAudioToPlay = false
            clearSongInfo()
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
