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

enum PartyAudioManagerState {
    case Inactive // No player or audio session setup; for when not a host
    case Empty // Host; no audio playing or to play
    case Paused // Host; audio is paused
    case Playing // Host; audio is playing
}

class PartyAudioManager: NSObject {
    
    var state: PartyAudioManagerState = .Inactive
    private var stateTime: Double = 0.0
    private let stateServicePeriod = 0.1 // Period in seconds of how often to update state
    
    private var emptyStateTimeSinceLastGetNextSong = 0.0
    private let emptyStateGetNextSongRefreshPeriod = 10.0
    
    private let songTimeRemainingToQueueNextSong = 5.0
    
    private var playingStateTimeSinceLastMPNowPlayingRefresh = 0.0
    private let playingStateMPNowPlayingRefreshPeriod = 1.0
    
    internal var userHasPressedPlay = false
    private var attemptedToQueueSongForThisSong = false
    
    var audioPlayer: STKAudioPlayer?
    var audioSession: AVAudioSession!
    
    override init() {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleAudioSessionInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleMediaServicesReset", name: AVAudioSessionMediaServicesWereResetNotification, object: nil)
        
        audioSession = AVAudioSession.sharedInstance()
        setState(.Inactive)
        
        NSTimer.scheduledTimerWithTimeInterval(stateServicePeriod, target: self, selector: "serviceState", userInfo: nil, repeats: true)
    }
    
    func setState(newState: PartyAudioManagerState) {
        state = newState
        stateTime = 0.0
        let partyManager = PartyManager.sharedParty
        
        switch newState {
        case .Inactive:
            if audioPlayer != nil { audioPlayer!.stop() }
            audioPlayer = nil
            audioSession.setCategory(AVAudioSessionCategoryAmbient, error: nil)
            userHasPressedPlay = false
            attemptedToQueueSongForThisSong = false
            UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        case .Empty:
            emptyStateTimeSinceLastGetNextSong = 0.0
            attemptedToQueueSongForThisSong = false
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
    }
    
    func serviceState() {
        stateTime += stateServicePeriod
        let partyManager = PartyManager.sharedParty
        
        switch state {
        case .Inactive:
            if partyManager.userIsHost {
                if initializeAudioSessionForPlaying() {
                    initializeAudioPlayerForPlaying()
                    setState(.Empty)
                    return
                }
            }
            
        case .Empty:
            emptyStateTimeSinceLastGetNextSong += stateServicePeriod
            
            if !partyManager.userIsHost {
                setState(.Inactive)
                return
            }
            
            if partyManager.currentSong != nil && partyManager.currentUser != nil {
                let songToPlay = SCClient.sharedClient.getSongURLString(partyManager.currentSong!.externalID)
                audioPlayer!.play(songToPlay)
                
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
            if !partyManager.userIsHost {
                setState(.Inactive)
                return
            }
            
        case .Playing:
            playingStateTimeSinceLastMPNowPlayingRefresh += stateServicePeriod
            
            if !partyManager.userIsHost {
                setState(.Inactive)
                return
            }
            
            // TODO: add a PausedNoConnection state for this event
            if !AFNetworkReachabilityManager.sharedManager().reachable {
                setState(.Inactive)
                return
            }

            let progress = audioPlayer!.progress // Number of seconds into the song
            let duration = audioPlayer!.duration // Song length in seconds
            
            if duration < 0.000001 {
                // "in between" songs; duration is 0
                partyManager.delegate.updateSongProgress(0.0)
            } else {
                let progressPercent = Float(progress / duration)
                partyManager.delegate.updateSongProgress(progressPercent)
                
                // Try queueing the next song
                let timeRemaining = duration - progress
                if timeRemaining < songTimeRemainingToQueueNextSong && !attemptedToQueueSongForThisSong {
                    attemptedToQueueSongForThisSong = true
                    
                    partyManager.queueNextSong(completion: {
                        let queueSongID = partyManager.queueSong?.externalID
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
    
    func initializeAudioSessionForPlaying() -> Bool {
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
    
    func initializeAudioPlayerForPlaying() {
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

        attemptedToQueueSongForThisSong = false
        let partyManager = PartyManager.sharedParty
        
        partyManager.delegate.updateSongProgress(0.0)
        
        // If there's a queued song
        if partyManager.setQueueSongAndUserToCurrent() {
            partyManager.setDelegatePreparedToPlaySong()
        } else {
            setState(.Empty)
        }
    }
    
    // Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
    func audioPlayer(audioPlayer: STKAudioPlayer!, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        
    }
}

extension PartyAudioManager {
    // MARK: handling AVAudioSession notifications
    func handleAudioSessionInterruption(n: NSNotification) {
        if n.name != AVAudioSessionInterruptionNotification || n.userInfo == nil || !PartyManager.sharedParty.userIsHost { return }
        
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
                setState(.Paused)
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
                    setState(.Playing)
                }
            }
        }
    }
    
    // Apple: "Responding to a Media Server Reset"
    // Apple says it's rare but can happen
    func handleMediaServicesReset() {
        setState(.Inactive)
    }
}