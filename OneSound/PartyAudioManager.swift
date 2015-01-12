//
//  PartyAudioManager.swift
//  OneSound
//
//  Created by adam on 1/6/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

let PartyAudioManagerStateChangeNotification = "PartyAudioManagerStateChange"

enum PartyAudioManagerState {
    case Inactive // No player or audio session setup; for when not a host
    case Empty // Host; no audio playing or to play
    case Paused // Host; audio is paused
    case Playing // Host; audio is playing
}

class PartyAudioManager: NSObject {
    
    private(set) var state: PartyAudioManagerState = .Inactive
    private var stateTime: Double = 0.0
    private let stateServicePeriod = 0.1 // Period in seconds of how often to update state
    
    private var emptyStateTimeSinceLastGetNextSong = 0.0
    private let emptyStateGetNextSongRefreshPeriod = 10.0
    
    private let songTimeRemainingToQueueNextSong = 5.0
    
    private var playingStateTimeSinceLastMPNowPlayingRefresh = 0.0
    private let playingStateMPNowPlayingRefreshPeriod = 1.0
    
    private var userHasPressedPlay = false
    private var attemptedToQueueSongForCurrentSong = false
    
    private var audioPlayer: STKAudioPlayer?
    private var audioSession: AVAudioSession!
    
    override init() {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleAudioSessionInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleMediaServicesReset", name: AVAudioSessionMediaServicesWereResetNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSongWasAddedNotification", name: PartySongWasAddedNotification, object: nil)
        
        audioSession = AVAudioSession.sharedInstance()
        setState(.Inactive)
        
        NSTimer.scheduledTimerWithTimeInterval(stateServicePeriod, target: self, selector: "serviceState", userInfo: nil, repeats: true)
    }
    
    private func setState(newState: PartyAudioManagerState) {
        state = newState
        stateTime = 0.0
        let partyManager = PartyManager.sharedParty
        
        switch newState {
        case .Inactive:
            if audioPlayer != nil { audioPlayer!.stop() }
            audioPlayer = nil
            audioSession.setCategory(AVAudioSessionCategoryAmbient, error: nil)
            userHasPressedPlay = false
            attemptedToQueueSongForCurrentSong = false
            UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        case .Empty:
            emptyStateTimeSinceLastGetNextSong = 0.0
            attemptedToQueueSongForCurrentSong = false
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            partyManager.clearSongInfo()
            partyManager.getNextSong()
        case .Paused:
            audioPlayer!.pause()
            partyManager.delegate.setAudioPlayerButtonsForPlaying(false)
        case .Playing:
            playingStateTimeSinceLastMPNowPlayingRefresh = 0.0
            audioPlayer!.resume()
            partyManager.delegate.setAudioPlayerButtonsForPlaying(true)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(PartyAudioManagerStateChangeNotification, object: nil)
    }
    
    func serviceState() {
        stateTime += stateServicePeriod
        let partyManager = PartyManager.sharedParty
        
        switch state {
        case .Inactive:
            if partyManager.state == .HostStreamable {
                onUserBecameHostStreamable()
                return
            }
            
        case .Empty:
            emptyStateTimeSinceLastGetNextSong += stateServicePeriod
            
            if partyManager.state != .HostStreamable { onUserNoLongerHostStreamable(); return }
            if !AFNetworkReachabilityManager.sharedManager().reachable { onNetworkNotReachable(); return }
            
            // Got next song
            if partyManager.hasCurrentSongAndUser {
                let songToPlay = SCClient.sharedClient.getSongURLString(partyManager.currentSong!.getExternalIDForPlaying())
                audioPlayer!.play(songToPlay)
                postPartyCurrentSongChangeUpdates()
                
                if userHasPressedPlay {
                    setState(.Playing)
                    return
                } else {
                    setState(.Paused)
                    return
                }
            }
            
            if emptyStateTimeSinceLastGetNextSong > emptyStateGetNextSongRefreshPeriod {
                emptyStateTimeSinceLastGetNextSong = 0.0
                partyManager.getNextSong()
            }
            
        case .Paused:
            if partyManager.state != .HostStreamable { onUserNoLongerHostStreamable(); return }
            if !partyManager.hasCurrentSongAndUser { onPartyNoLongerHasCurrentSong(); return }
            if !AFNetworkReachabilityManager.sharedManager().reachable { onNetworkNotReachable(); return }
            
        case .Playing:
            playingStateTimeSinceLastMPNowPlayingRefresh += stateServicePeriod
            
            if partyManager.state != .HostStreamable { onUserNoLongerHostStreamable(); return }
            if !partyManager.hasCurrentSongAndUser { onPartyNoLongerHasCurrentSong(); return }
            if !AFNetworkReachabilityManager.sharedManager().reachable { onNetworkNotReachable(); return }

            let progress = audioPlayer!.progress // Number of seconds into the song
            let duration = audioPlayer!.duration // Song length in seconds
            
            if duration < 0.001 {
                // "in between" songs; duration is 0
                partyManager.delegate.updateCurrentSongProgress(0.0)
            } else {
                let progressPercent = Float(progress / duration)
                partyManager.delegate.updateCurrentSongProgress(progressPercent)
                
                // Try queueing the next song
                let timeRemaining = duration - progress
                if timeRemaining < songTimeRemainingToQueueNextSong && !attemptedToQueueSongForCurrentSong {
                    attemptedToQueueSongForCurrentSong = true
                    
                    partyManager.queueNextSong(completion: {
                        let queueSongID = partyManager.queueSong?.getExternalIDForPlaying()
                        if queueSongID != nil {
                            let songToQueue = SCClient.sharedClient.getSongURLString(queueSongID!)
                            self.audioPlayer!.queue(songToQueue)
                        }
                    })
                }
                
                // Refresh the MPNowPlayingInfo
                if playingStateTimeSinceLastMPNowPlayingRefresh < playingStateMPNowPlayingRefreshPeriod {
                    playingStateTimeSinceLastMPNowPlayingRefresh = 0.0
                    partyManager.updateMPNowPlayingInfoCenterInfo(elapsedTime: progress)
                }
            }
        }
    }
    
    func onPlayButton() {
        userHasPressedPlay = true
        setState(.Playing)
    }
    
    func onPauseButton() {
        setState(.Paused)
    }
    
    func onSongSkip() {
        // TODO: make this work
    }
    
    private func onSongFinishedWithNoQueuedSong() {
        setState(.Empty)
    }
    
    private func onSongFinishedWithQueuedSong() {
        postPartyCurrentSongChangeUpdates()
    }
    
    private func onPartyNoLongerHasCurrentSong() {
        setState(.Empty)
    }
    
    private func onGotNextSongPlayAlreadyPressed() {
        setState(.Playing)
    }
    
    private func onGotNextSongPlayNotAlreadyPressed() {
        setState(.Paused)
    }
    
    private func onUserBecameHostStreamable() {
        if initializeAudioSessionForPlaying() {
            initializeAudioPlayerForPlaying()
            setState(.Empty)
            return
        }
    }
    
    private func onUserNoLongerHostStreamable() {
        setState(.Inactive)
    }
    
    private func onNetworkNotReachable() {
        setState(.Inactive)
    }
    
    private func onAudioInterruptionBegan() {
        setState(.Paused)
    }
    
    private func onAudioInterruptionEndedShouldResume() {
        setState(.Playing)
    }
    
    private func onMediaServicesReset() {
        setState(.Inactive)
    }
    
    private func postPartyCurrentSongChangeUpdates() {
        NSNotificationCenter.defaultCenter().postNotificationName(PartyCurrentSongDidChangeNotification, object: nil)
        PartyManager.sharedParty.updateMPNowPlayingInfoCenterInfo()
    }
    
    func handleSongWasAddedNotification() {
        // Selector must be public for responding to notifications
        if state == .Empty {
            emptyStateTimeSinceLastGetNextSong = 0.0
            PartyManager.sharedParty.getNextSong()
        }
    }
    
    func resetEmptyStateTimeSinceLastGetNextSong() {
        emptyStateTimeSinceLastGetNextSong = 0.0
    }
    
    private func initializeAudioSessionForPlaying() -> Bool {
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
    
    private func initializeAudioPlayerForPlaying() {
        // Setup audio player
        let equalizerB:(Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32) = (50, 100, 200, 400, 800, 600, 2600, 16000, 0, 0, 0, 0, 0, 0 , 0, 0, 0, 0, 0, 0, 0, 0 , 0, 0 )
        var optns:STKAudioPlayerOptions = STKAudioPlayerOptions(flushQueueOnSeek: true, enableVolumeMixer: true, equalizerBandFrequencies:equalizerB,readBufferSize: (64 * 1024), bufferSizeInSeconds: 10, secondsRequiredToStartPlaying: 1, gracePeriodAfterSeekInSeconds: 0.5, secondsRequiredToStartPlayingAfterBufferUnderun: 7.5)
        
        audioPlayer = STKAudioPlayer(options: optns)
        audioPlayer!.meteringEnabled = true
        audioPlayer!.volume = 1
        audioPlayer!.delegate = self
    }
}

extension PartyAudioManager: STKAudioPlayerDelegate {
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
        
        attemptedToQueueSongForCurrentSong = false
        let partyManager = PartyManager.sharedParty
        
        // Song was most likely unstreamable if finished playing with such small amt of time
        if progress < 0.5 {
            var songInfo = ""
            if let currentSongName = partyManager.currentSong?.name {
                if let currentSongArtist = partyManager.currentSong?.artistName {
                    songInfo = "'\(currentSongName)' uploaded by '\(currentSongArtist)' "
                } else {
                    songInfo = "'\(currentSongName)' "
                }
            }
            
            partyManager.delegate.refresh()
            
            let alertMessage = "The SoundCloud song \(songInfo)being played could not be streamed. To play this song, try searching for a different version of it, or getting it from a different uploader"
            let alert = UIAlertView(title: "Unstreamable Song Skipped", message: alertMessage, delegate: nil, cancelButtonTitle: "Okay")
            alert.show()
        }
        
        partyManager.delegate.updateCurrentSongProgress(0.0)
        
        // If there's a queued song
        if partyManager.setQueueSongAndUserToCurrent() {
            onSongFinishedWithQueuedSong()
        } else {
            onSongFinishedWithNoQueuedSong()
        }
    }
    
    // Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
    func audioPlayer(audioPlayer: STKAudioPlayer!, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        
    }
}

extension PartyAudioManager {
    // MARK: handling AVAudioSession notifications
    func handleAudioSessionInterruption(n: NSNotification) {
        if n.name != AVAudioSessionInterruptionNotification || n.userInfo == nil
            || PartyManager.sharedParty.state != .HostStreamable { return }
        
        println("AVAudioSessionInterruptionNotification")
        var info = n.userInfo!
        var interruptionTypeValue: UInt = 0
        (info[AVAudioSessionInterruptionTypeKey] as NSValue).getValue(&interruptionTypeValue)
        if let type = AVAudioSessionInterruptionType(rawValue: interruptionTypeValue) {
            switch type {
            case .Began:
                // Audio has stopped, already inactive
                // Change state of UI, etc., to reflect non-playing state
                println("began")
                onAudioInterruptionBegan()
            case .Ended:
                // Make session active
                // Update user interface
                println("ended")
                var interruptionOptionValue: UInt = 0
                (info[AVAudioSessionInterruptionOptionKey] as NSValue).getValue(&interruptionOptionValue)
                let option = AVAudioSessionInterruptionOptions(rawValue: interruptionOptionValue)
                if option == AVAudioSessionInterruptionOptions.OptionShouldResume {
                    // AVAudioSessionInterruptionOptionShouldResume option
                    // Here you should continue playback
                    onAudioInterruptionEndedShouldResume()
                }
            }
        }
    }
    
    // Apple: "Responding to a Media Server Reset"
    // Apple says it's rare but can happen
    func handleMediaServicesReset() {
        onMediaServicesReset()
    }
}