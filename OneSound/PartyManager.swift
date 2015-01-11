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
    func updateCurrentSongProgress(progress: Float)
    func setAudioPlayerButtonsForPlaying(audioPlayerIsPlaying: Bool)
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
    
    var delegate: PartyManagerDelegate!
    
    let playlistManager = PartyPlaylistManager()
    let membersManager = PartyMembersManager()
    private(set) var audioManager: PartyAudioManager!
    
    private(set) var partyID: Int!
    private(set) var isPrivate: Bool! = false
    private(set) var name: String!
    private(set) var strictness: Int!
    private var userIsHost: Bool! = false // Use the state to check host status, NOT the bool
    private var userHasMusicControl: Bool! = false // Use the state to check streaming status, NOT the bool
    private var userCanSkipSong: Bool! = false
    
    private(set) var currentSong: Song?
    private(set) var currentUser: User?
    private(set) var queueSong: Song?
    private(set) var queueUser: User?
    var hasCurrentSong: Bool { return currentSong != nil && currentUser != nil }
    
    private(set) var state: PartyManagerState = .None
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
        let oldState = state
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
    
    func refresh(completion: completionClosure? = nil) {
        timeSinceLastGetCurrentParty = 0.0
        
        if AFNetworkReachabilityManager.sharedManager().reachable && UserManager.sharedUser.setup {
            getCurrentParty(
                completion: {
                    if self.userIsHost == true {
                        if self.state != .Host { self.setState(.Host) }
                    } else {
                        if self.state != .Member { self.setState(.Member) }
                    }
                    if completion != nil { completion!() }
                },
                noCurrentParty: {
                    if self.state != .None { self.setState(.None) }
                    if completion != nil { completion!() }
                },
                failureAddOn: {
                    if self.state != .None { self.setState(.None) }
                    if completion != nil { completion!() }
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
    
    // Make sure to use this AFTER updateDelegateSongImage() and updateDelegateSongInformation()
    func updateMPNowPlayingInfoCenterInfo(elapsedTime: Double = 0) {
        if currentSong != nil {
            if currentSong!.artworkURL != nil {
                let largerArtworkURL = currentSong!.artworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                let currentSongImageCache = getAppDelegate().currentSongImageCache
                currentSongImageCache.queryDiskCacheForKey(largerArtworkURL,
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
        
        if userIsHost != nil && userIsHost == true {
            userHasMusicControl = json["host_info"]["music_control"].bool
            userCanSkipSong = json["host_info"]["skip_song"].bool
        } else {
            userHasMusicControl = false
            userCanSkipSong = false
        }
        
        if json["current_song"]["user"].object != nil {
            // Got a song for the party
            let oldCurrentSong = currentSong
            currentSong = Song(json: json["current_song"])
            currentUser = User(json: json["current_song"]["user"])
            
            if oldCurrentSong == nil {
                // Got a song when there previously wasn't one, so must be a song change
                postPartySongDidChangeNotificationBasedOnState()
            } else if oldCurrentSong != nil && currentSong! != oldCurrentSong {
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