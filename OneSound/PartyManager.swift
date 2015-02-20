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
    func getCurrentSongProgress() -> Float
    func setAudioPlayerButtonsForPlaying(audioPlayerIsPlaying: Bool)
    func refresh()
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
    var hasCurrentSongAndUser: Bool { return currentSong != nil && currentUser != nil }
    
    private(set) var state: PartyManagerState = .None
    private var stateTime: Double = 0.0
    private let stateServicePeriod = 0.1 // Period in seconds of how often to update state
    
    private var timeSinceLastGetCurrentParty = 0.0
    let getCurrentPartyRefreshPeriod = 10.0
    
    // These are used to show the alerts after the loggingInSpashViewController / login flow is finished
    var lostMusicControlAlertShouldBeShown = false
    var noMusicControlAlertShouldBeShown = false
    
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
    
    // Things that must be done after the shared singleton instance os intantiated
    func prepareAfterInit() {
        setupAudioManager()
    }
    
    // MUST be used; called after the PartyManager shared instance is instantiated in AppDelegate
    func setupAudioManager() {
        audioManager = PartyAudioManager()
    }
    
    func setState(newState: PartyManagerState) {
        let oldState = state
        state = newState
        stateTime = 0.0
        
        lostMusicControlAlertShouldBeShown = false
        noMusicControlAlertShouldBeShown = false
        
        switch newState {
        case .None:
            resetAllPartyInfo()
        case .Host:
            if oldState == .HostStreamable {
                if loggingInSpashViewControllerIsShowing {
                    // Wait until done logging in, let PartyMainViewController handle when to show it
                    lostMusicControlAlertShouldBeShown = true
                } else {
                    // Show the alert right now
                    AlertManager.sharedManager.showAlert(createLostMusicControlAlert())
                }
            } else {
                if loggingInSpashViewControllerIsShowing {
                    // Wait until done logging in, let PartyMainViewController handle when to show it
                    noMusicControlAlertShouldBeShown = true
                } else {
                    // Show the alert right now
                    AlertManager.sharedManager.showAlert(createNoMusicControlAlert())
                }
            }
        default:
            break
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(PartyManagerStateChangeNotification, object: nil)
    }
    
    func serviceState() {
        stateTime += stateServicePeriod
        timeSinceLastGetCurrentParty += stateServicePeriod
        
        // Make sure to check this first, or else failing getCurrentParty calls will be made
        if !AFNetworkReachabilityManager.sharedManager().reachable && !UserManager.sharedUser.setup {
            if state != .None { setState(.None) }
        }
        
        if timeSinceLastGetCurrentParty > getCurrentPartyRefreshPeriod {
            refresh()
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
                    self.decideStateOfValidParty()
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
    
    // Only use this when you know the user is in a valid party
    // (completion block of getCurrentParty or the completion block of joining a party)
    private func decideStateOfValidParty() {
        if userHasMusicControl == true {
            if state != .HostStreamable { setState(.HostStreamable) }
        } else if self.userIsHost == true {
            if state != .Host { setState(.Host) }
        } else {
            if state != .Member { setState(.Member) }
        }
        
        delegate.refresh()
    }
    
    private func postPartySongDidChangeNotificationBasedOnState() {
        if state != .Host {
            NSNotificationCenter.defaultCenter().postNotificationName(PartyCurrentSongDidChangeNotification, object: nil)
        }
    }
    
    // Only to be used for hosts
    func getNextSong(skipped: Bool) {
        audioManager.resetEmptyStateTimeSinceLastGetNextSong()
        getNextSong(partyID, skipped: skipped,
            completion: { song, user in
                self.currentSong = song
                self.currentUser = user
            }, noCurrentSong: {
                
            }, failureAddOn: {
                
            }
        )
    }
    
    // Only to be used for hosts
    func queueNextSong(skipped: Bool, completion: completionClosure? = nil) {
        getNextSong(partyID, skipped: skipped,
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
                        // If the current song is still non-nil after the query
                        if self.currentSong != nil {
                            if image != nil {
                                let artwork = MPMediaItemArtwork(image: image)
                                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : self.currentSong!.artistName,  MPMediaItemPropertyTitle : self.currentSong!.name, MPMediaItemPropertyArtwork : artwork, MPMediaItemPropertyPlaybackDuration : self.currentSong!.duration, MPNowPlayingInfoPropertyElapsedPlaybackTime : elapsedTime]
                            } else {
                                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : self.currentSong!.artistName,  MPMediaItemPropertyTitle : self.currentSong!.name, MPMediaItemPropertyPlaybackDuration : self.currentSong!.duration, MPNowPlayingInfoPropertyElapsedPlaybackTime : elapsedTime]
                                
                            }
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
    
    private func resetManagers() {
        playlistManager.reset()
        membersManager.reset()
    }
    
    private func initializeManagers() {
        playlistManager.clearForUpdate()
        membersManager.clearForUpdate()
        playlistManager.update()
        membersManager.update()
    }
    
    func resetAllPartyInfo() {
        clearSongInfo()
        resetManagers()
        
        partyID = 0
        isPrivate = false
        name = ""
        strictness = 0
        
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
                let responseJSON = JSON(responseObject)
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
    
    func getNextSong(pid: Int, skipped: Bool, completion: ((song: Song, user: User) -> ())? = nil, noCurrentSong: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        
        if state == .HostStreamable {
            OSAPI.sharedClient.GETNextSong(pid, skipped: skipped,
                success: { data, responseObject in
                    let responseJSON = JSON(responseObject)
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
        setState(.None)
        
        if pid != 0 {
            let user = UserManager.sharedUser
            OSAPI.sharedClient.GETParty(pid,
                success: { data, responseObject in
                    let responseJSON = JSON(responseObject)
                    //println(responseJSON)
                    self.updateMainPartyInfoFromJSON(responseJSON, completion: JSONUpdateCompletion)
                    //self.refresh()
                    self.decideStateOfValidParty()
                    self.initializeManagers()
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
                let responseJSON = JSON(responseObject)
                println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    // Update new party information
                    self.updateMainPartyInfoFromJSON(responseJSON, completion: {
                        self.decideStateOfValidParty()
                        self.resetManagers()
                        respondToChangeAttempt(true)
                    })
                    //self.refresh()
                    //self.resetManagers()
                    //respondToChangeAttempt(true)
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
                let responseJSON = JSON(responseObject)
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
                let responseJSON = JSON(responseObject)
                println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    self.setState(.None)
                    self.resetManagers()
                    respondToChangeAttempt(true)
                } else {
                    // Server didn't accept request to leave party
                    respondToChangeAttempt(false)
                }
            }, failure: defaultAFHTTPFailureBlock
        )
    }
    
    func getMusicStreamControl(# respondToChangeAttempt: (Bool) -> ()) {
        
        OSAPI.sharedClient.PUTPartyPermissions(partyID, musicControl: true,
            success: { data, responseObject in
                let responseJSON = JSON(responseObject)
                println(responseJSON)
                let status = responseJSON["status"].string
                
                if status == "success" {
                    //self.refresh()
                    self.userHasMusicControl = true
                    // TODO: what should the bool for userCanSkipSong be after getting music stream control?
                    self.setState(.HostStreamable)
                    respondToChangeAttempt(true)
                } else {
                    // Server didn't accept request for new party with supplied information
                    respondToChangeAttempt(false)
                }
            }, failure: defaultAFHTTPFailureBlock
        )
    }
    
    private func updateMainPartyInfoFromJSON(json: JSON, completion: completionClosure? = nil) {
        println(json)
        
        partyID = json["pid"].int
        isPrivate = json["privacy"].bool
        name = json["name"].string
        strictness = json["strictness"].int
        userIsHost = json["host"].bool
        
        if userIsHost != nil && userIsHost == true {
            userHasMusicControl = json["host_info"]["music_control"].bool
            userCanSkipSong = json["host_info"]["skip_song"].bool
        } else {
            userHasMusicControl = false
            userCanSkipSong = false
        }
        
        if json["current_song"]["user"] != nil {
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

extension PartyManager {
    // MARK: UIAlertView related code
    
    func createLostMusicControlAlert() -> UIAlertView {
        let alert = UIAlertView(title: "Lost Music Control", message: "Another device with your account has taken the music control. You still have the same Host control, but the music will play through the other device. To get music control back, go to the Party Settings", delegate: self, cancelButtonTitle: defaultAlertCancelButtonText)
        alert.tag = AlertTag.LostMusicControl.rawValue
        return alert
    }
    
    func createNoMusicControlAlert() -> UIAlertView {
        let alert = UIAlertView(title: "No Music Control", message: "Another device with your account has the music control. You still have the same Host control, but the music will play through the other device. To get music control back, go to the Party Settings", delegate: self, cancelButtonTitle: defaultAlertCancelButtonText)
        alert.tag = AlertTag.NoMusicControl.rawValue
        return alert
    }
}