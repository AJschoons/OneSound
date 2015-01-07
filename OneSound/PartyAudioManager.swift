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
    
    weak var partyManager: PartyManager!
    
    var state: PartyAudioManagerState = .Inactive
    private var stateTime: Double = 0.0
    private let stateServicePeriod = 0.5 // Period in seconds of how often to update state
    
    private var emptyStateTime = 0.0
    let emptyStateGetNextSongRefreshPeriod = 5.0
    
    private var userHasPressedPlay = false
    
    var audioPlayer: STKAudioPlayer?
    var audioSession: AVAudioSession!
    
    convenience init(partyManager: PartyManager) {
        self.init()
        
        self.partyManager = partyManager
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleAudioSessionInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleMediaServicesReset", name: AVAudioSessionMediaServicesWereResetNotification, object: nil)
        
        NSTimer.scheduledTimerWithTimeInterval(stateServicePeriod, target: self, selector: "serviceState", userInfo: nil, repeats: true)
        
        setState(.Inactive)
    }
    
    func setState(newState: PartyAudioManagerState) {
        state = newState
        stateTime = 0.0
        
        switch newState {
        case .Inactive:
            audioPlayer = nil
            audioSession.setCategory(AVAudioSessionCategoryAmbient, error: nil)
            userHasPressedPlay = false
        case .Empty:
            emptyStateTime = 0.0
        default:
            println("unhandled state")
        }
    }
    
    func serviceState() {
        stateTime += stateServicePeriod
        
        switch state {
        case .Inactive:
            if partyManager.userIsHost {
                if initializeAudioSessionForPlaying() {
                    initializeAudioPlayerForPlaying()
                    setState(.Empty)
                } else {
                    setState(.Inactive)
                }
            }
        case .Empty:
            emptyStateTime += stateServicePeriod
            if emptyStateTime > emptyStateGetNextSongRefreshPeriod {
                // call get next song
            }
        default:
            println("unhandled state")
        }
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
        
        if partyManager.setQueueSongAndUserToCurrent() {
            // If there's a queued song
            partyManager.audioPlayerIsPlaying = false
            partyManager.setDelegatePreparedToPlaySongFromQueue()
        } else {
            partyManager.audioPlayerIsPlaying = false
            partyManager.audioPlayerHasAudioToPlay = false
            partyManager.clearSongInfo()
            partyManager.getNextSongForDelegate()
        }
    }
    
    // Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
    func audioPlayer(audioPlayer: STKAudioPlayer!, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        
    }
}

extension PartyAudioManager {
    // MARK: handling AVAudioSession notifications
    func handleAudioSessionInterruption(n: NSNotification) {
        if n.name != AVAudioSessionInterruptionNotification || n.userInfo == nil || !partyManager.userIsHost { return }
        
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
                partyManager.pauseSong()
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
                    partyManager.playSong()
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