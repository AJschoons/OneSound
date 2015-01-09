//
//  PartyManager.swift
//  OneSound
//
//  Created by adam on 7/28/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

let PartyManagerStateChangeNotification = "PartyManagerStateChange"
let PartyCurrentSongDidChangeNotification = "PartyCurrentSongDidChange"

protocol PartyManagerDelegate {
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

enum PartyManagerState {
    case None // User has no party
    case Member // User is member of a party
    case Host // User is hosting party
    case HostStreamable // User is hosting party and this is the device that's streaming
    
}

class PartyManager: NSObject {
    
    let songImageCache = (UIApplication.sharedApplication().delegate as AppDelegate).songImageCache
    
    var delegate: PartyManagerDelegate!
    
    let playlistManager = PartyPlaylistManager()
    let membersManager = PartyMembersManager()
    var audioManager: PartyAudioManager!
    
    var partyID: Int!
    var isPrivate: Bool! = false
    var name: String!
    var strictness: Int!
    private var userIsHost: Bool! = false
    
    var currentSong: Song?
    var currentUser: User?
    var queueSong: Song?
    var queueUser: User?
    
    var state: PartyManagerState = .None
    private var stateTime: Double = 0.0
    private let stateServicePeriod = 0.1 // Period in seconds of how often to update state
    
    private var timeSinceLastGetCurrentParty = 0.0
    private let getCurrentPartyRefreshPeriod = 10.0
    
    class var sharedParty: PartyManager {
        struct Static {
            static let partyManager = PartyManager()
        }
        return Static.partyManager
    }
    
    override init() {
        super.init()
        
        // Refresh the party info when the user info changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshForUserInfoChange", name: UserManagerInformationDidChangeNotification, object: nil)
        
        NSTimer.scheduledTimerWithTimeInterval(stateServicePeriod, target: self, selector: "serviceState", userInfo: nil, repeats: true)
        
        // Make sure to call setupAudioManager after init
    }
    
    // MUST be used; called after the PartyManager shared instance is instantiated in AppDelegate
    func setupAudioManager() {
        audioManager = PartyAudioManager()
    }
    
    func setState(newState: PartyManagerState) {
        state = newState
        stateTime = 0.0
        
        var somethingToDoOtherThanPrintln = true
        switch newState {
        case .None:
            somethingToDoOtherThanPrintln = true
            resetAllPartyInfo()
        case .Member:
            somethingToDoOtherThanPrintln = true
        case .Host:
            somethingToDoOtherThanPrintln = true
        case .HostStreamable:
            // state not handled, yet
            somethingToDoOtherThanPrintln = true
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(PartyManagerStateChangeNotification, object: nil)
    }
    
    func serviceState() {
        stateTime += stateServicePeriod
        timeSinceLastGetCurrentParty += stateServicePeriod
        
        if timeSinceLastGetCurrentParty > getCurrentPartyRefreshPeriod {
            refresh()
        }
        
        var somethingToDoOtherThanPrintln = true
        switch state {
        case .None:
            somethingToDoOtherThanPrintln = true
        case .Member:
            somethingToDoOtherThanPrintln = true
        case .Host:
            somethingToDoOtherThanPrintln = true
        case .HostStreamable:
            // state not handled, yet
            somethingToDoOtherThanPrintln = true
        }
    }
    
    func refreshForUserInfoChange() {
        if state != .None { setState(.None) }
        refresh()
    }
    
    func refresh() {
        timeSinceLastGetCurrentParty = 0.0
        
        if AFNetworkReachabilityManager.sharedManager().reachable && UserManager.sharedUser.setup {
            getCurrentParty(
                completion: {
                    if self.userIsHost == true {
                        if self.state != .Host { self.setState(.Host) }
                    } else {
                        if self.state != .Member { self.setState(.Member) }
                    }
                },
                noCurrentParty: {
                    if self.state != .None { self.setState(.None) }
                },
                failureAddOn: {
                    if self.state != .None { self.setState(.None) }
                }
            )
        } else {
            if state != .None { setState(.None) }
        }
    }
    
    func postPartySongDidChangeNotificationBasedOnState() {
        if state != .Host {
            NSNotificationCenter.defaultCenter().postNotificationName(PartyCurrentSongDidChangeNotification, object: nil)
        }
    }
    /*
    func refresh() {
        println("refreshing PartyManager")
        
        
        let user = UserManager.sharedUser
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if UserManager.sharedUser.setup == true {
                if UserManager.sharedUser.party != nil && UserManager.sharedUser.party != 0 {
                    if setup == true {
                        setDelegatePartyInfoVisible()
                        
                        if userIsHost == true {
                            refreshForHost()
                        } else {
                            refreshForNonHost()
                        }
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
            dispatchAsyncToMainQueue(action: {
                self.delegate.showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
                self.delegate.setPartyMainVCRightBarButton(create: false, leave: false, settings: false)
                self.delegate.setPartyInfoHidden(true)
            })
        }

    }*/
    /*
    func refreshForHost() {
        dispatchAsyncToMainQueue(action: {
            self.delegate.setPartyMainVCRightBarButton(create: false, leave: false, settings: true)
        })
        
        if audioManager.state == .Empty {
            dispatchAsyncToMainQueue(action: {
                self.delegate.setPartySongImage(songToPlay: false, artworkToShow: false, loadingSong: false, image: nil)
            })
            //getNextSong()
        } else if audioManager.state == .Paused || audioManager.state == .Playing {
            //updateCurrentSongAndUserThenDelegate(onlyUpdateCurrentUserInfo: true)
        }
    }
    
    func refreshForNonHost() {
        dispatchAsyncToMainQueue(action: {
            self.delegate.setPartyMainVCRightBarButton(create: false, leave: true, settings: false)
        })
        
        //updateCurrentSongAndUserThenDelegate()
    }
    */
    /*
    func setDelegatePartyInfoVisible() {
        // Party is actually setup
        println("party is setup")
        dispatchAsyncToMainQueue(action: {
            self.delegate.hideMessages()
            self.delegate.setPartyInfoHidden(false)
        })
        println("user is host: \(userIsHost)")
    }*/
    
    /*
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
    */
    
    // Only to be used for hosts
    func getNextSong() {
        getNextSong(partyID,
            completion: { song, user in
                self.currentSong = song
                self.currentUser = user
            }, noCurrentSong: {
                
            }, failureAddOn: {
                
            }
        )
    }
    
    // Only to be used for hosts
    func queueNextSong(completion: completionClosure? = nil) {
        getNextSong(partyID,
            completion: { song, user in
                self.queueSong = song
                self.queueUser = user
                if completion != nil { completion!() }
            }, noCurrentSong: {
                
            }, failureAddOn: {
                
            }
        )
    }
    
    // Only for hosts
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
    
    /*
    func setDelegatePreparedToPlaySong() {
        
        //updateDelegateSongAndUserInformation()
        //updateMPNowPlayingInfoCenterInfo()
        
        //audioPlayer.play(songURLString)
        //playSong()
    }*/
    
    func skipSong() {
        // TODO: make this work
        /*
        if audioPlayer.state == STKAudioPlayerStatePlaying {
        pauseSong()
        getNextSongForDelegate()
        }
        */
    }
    
    /*
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
    */
    
    /*
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
    */
    
    // Make sure to use this AFTER updateDelegateSongImage() and updateDelegateSongInformation()
    func updateMPNowPlayingInfoCenterInfo(elapsedTime: Double = 0) {
        if currentSong != nil {
            if currentSong!.artworkURL != nil {
                let largerArtworkURL = currentSong!.artworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                songImageCache.queryDiskCacheForKey(largerArtworkURL,
                    done: { image, imageCacheType in
                        if image != nil && self.currentSong != nil {
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
    
    func clearSongInfo() {
        currentSong = nil
        currentUser = nil
        queueSong = nil
        queueUser = nil
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = ["" : ""]
    }
    
    func resetAllPartyInfo() {
        clearSongInfo()
        
        partyID = 0
        isPrivate = false
        name = ""
        strictness = 0
        
        playlistManager.reset()
        membersManager.reset()
        currentSong = nil
        currentUser = nil
        queueSong = nil
        queueUser = nil
        
        userIsHost = false
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = ["" : ""]
        
        dispatchAsyncToMainQueue(action: {
            self.delegate.setPartyInfoHidden(true)
        })
    }
}

extension PartyManager {
    // MARK: Party networking related code for user's active party
    
    // Used to get the user's party and refresh all the info
    func getCurrentParty(completion: completionClosure? = nil, noCurrentParty: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        OSAPI.sharedClient.GETPartyCurrent(
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                
                self.updateMainPartyInfoFromJSON(responseJSON, completion: completion)
            }, failure: { task, error in
                var shouldDoDefaultFailureBlock = true
                
                if let response = task.response as? NSHTTPURLResponse {
                    println("errorResponseCode:\(response.statusCode)")
                    if response.statusCode == 404 && noCurrentParty != nil {
                        shouldDoDefaultFailureBlock = false
                        if noCurrentParty != nil {
                            noCurrentParty!()
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
    
    func getNextSong(pid: Int, completion: ((song: Song, user: User) -> ())? = nil, noCurrentSong: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        
        if state != .None {
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
    
    /*
    func updateCurrentSongAndUser(pid: Int, completion: completionClosure? = nil, noCurrentSong: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        
        if state != .None {
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
    */
    
    func joinParty(pid: Int, JSONUpdateCompletion: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        // Makes it so none of the old info stays when joining a party from an old one
        resetAllPartyInfo()
        
        if pid != 0 {
            let user = UserManager.sharedUser
            OSAPI.sharedClient.GETParty(pid,
                success: { data, responseObject in
                    let responseJSON = JSONValue(responseObject)
                    //println(responseJSON)
                    
                    self.updateMainPartyInfoFromJSON(responseJSON, JSONUpdateCompletion)
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
    
    func createNewParty(name: String, privacy: Bool, strictness: Int, respondToChangeAttempt: (Bool) -> (), failure: AFHTTPFailureBlock = defaultAFHTTPFailureBlockForSigningIn) {
        let user = UserManager.sharedUser
        
        OSAPI.sharedClient.POSTParty(name, privacy: privacy, strictness: strictness,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    // Update new party information
                    self.refresh()
                    respondToChangeAttempt(true)
                } else {
                    // Server didn't accept request for new party with supplied information
                    respondToChangeAttempt(false)
                }
            }, failure: defaultAFHTTPFailureBlock
        )
    }
    
    func changePartyInfo(name: String, privacy: Bool, strictness: Int, respondToChangeAttempt: (Bool) -> (), failure: AFHTTPFailureBlock = defaultAFHTTPFailureBlockForSigningIn) {
        let user = UserManager.sharedUser
        
        OSAPI.sharedClient.PUTParty(partyID, name: name, privacy: privacy, strictness: strictness,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    // Update new party information
                    self.name = name
                    self.isPrivate = privacy
                    self.strictness = strictness
                    respondToChangeAttempt(true)
                } else {
                    // Server didn't accept request for new party with supplied information
                    respondToChangeAttempt(false)
                }
            }, failure: defaultAFHTTPFailureBlock
        )
    }
    
    // Leaves a party. If successful, clears the party info. respondToChangeAttempt = true if left party, else false
    func leaveParty(# respondToChangeAttempt: (Bool) -> ()) {
        let user = UserManager.sharedUser
        OSAPI.sharedClient.DELETEUserParty(user.id,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    self.setState(.None)
                    respondToChangeAttempt(true)
                } else {
                    // Server didn't accept request for new party with supplied information
                    respondToChangeAttempt(false)
                }
            }, failure: defaultAFHTTPFailureBlock)
    }
    
    func updateMainPartyInfoFromJSON(json: JSONValue, completion: completionClosure? = nil) {
        println(json)
        
        partyID = json["pid"].integer
        isPrivate = json["privacy"].bool
        name = json["name"].string
        strictness = json["strictness"].integer
        userIsHost = json["host"].bool
        
        if json["current_song"]["user"].object != nil {
            // Got a song for the party
            let newCurrentSong = Song(json: json["current_song"])
            currentUser = User(json: json["current_song"]["user"])
            
            if currentSong == nil {
                // Got a song when there previously wasn't one, so must be a song change
                postPartySongDidChangeNotificationBasedOnState()
            } else if currentSong != nil && newCurrentSong != currentSong! {
                // The new song isn't the same as the old one; song change
                postPartySongDidChangeNotificationBasedOnState()
            }
        } else {
            // Did NOT get a song for the party
            if currentSong != nil {
                // There was a song, but now there isn't; song change
                postPartySongDidChangeNotificationBasedOnState()
            }
            
            currentSong = nil
            currentUser = nil
        }
        
        if completion != nil {
            completion!()
        }
    }
}

extension PartyManager {
    // MARK: Party networking related code for song voting
    
    func songUpvote(sid: Int) {
        let user = UserManager.sharedUser
        OSAPI.sharedClient.POSTSongUpvote(sid, success: nil, failure: defaultAFHTTPFailureBlock)
    }
    
    func songDownvote(sid: Int) {
        let user = UserManager.sharedUser
        OSAPI.sharedClient.POSTSongDownvote(sid, success: nil, failure: defaultAFHTTPFailureBlock)
    }
    
    func songClearVote(sid: Int) {
        let user = UserManager.sharedUser
        OSAPI.sharedClient.DELETESongVote(sid, success: nil, failure: defaultAFHTTPFailureBlock)
    }
}