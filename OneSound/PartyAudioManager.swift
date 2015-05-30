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
    
    private var currentSong: Song?
    
    private var hasAudio: Bool {
        return state == .Paused || state == .Playing
    }
    
    private(set) var state: PartyAudioManagerState = .Inactive
    private var stateTime: Double = 0.0
    private let StateServicePeriod = 0.1 // Period in seconds of how often to update state
    private let StateTimeGracePeriod = 1.0 // Period in seconds before a state is considered to be "in error" from audio player state
    
    private var movingFromInactiveToEmpty = false
    
    private var emptyStateTimeSinceLastGetNextSong = 0.0
    private let EmptyStateGetNextSongRefreshPeriod = 10.0
    private var emptyStatePreparingToPlayAudio = false
    
    private let SongTimeRemainingToQueueNextSong = 2.0
    
    private var playingStateTimeSinceLastMPNowPlayingRefresh = 0.0
    private let PlayingStateMPNowPlayingRefreshPeriod = 1.0
    
    private var userHasPressedPlay = false
    private var attemptedToQueueSongForCurrentSong = false
    
    private var songWasSkipped = false
    
    private var timeSinceLastSongAdded = 0.0
    private let TimeSinceLastSongAddedGracePeriod = 1.0
    
    private var audioPlayer: STKAudioPlayer?
    private var audioSession: AVAudioSession!
    
    private let MaxSongPlayAttempts = 4 // Try playing a song 3 more times when it prematurely ends with < 0.1 seconds
    
    override init() {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleAudioSessionInterruption:", name: AVAudioSessionInterruptionNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleMediaServicesReset", name: AVAudioSessionMediaServicesWereResetNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleAVAudioSessionRouteChangeNotification:", name: AVAudioSessionRouteChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSongWasAddedNotification", name: PartySongWasAddedNotification, object: nil)
        
        audioSession = AVAudioSession.sharedInstance()
        setState(.Inactive)
        
        NSTimer.scheduledTimerWithTimeInterval(StateServicePeriod, target: self, selector: "serviceState", userInfo: nil, repeats: true)
    }
    
    private func setState(newState: PartyAudioManagerState) {
        state = newState
        stateTime = 0.0
        let partyManager = PartyManager.sharedParty
        
        switch newState {
            
        case .Inactive:
            currentSong = nil
            if audioPlayer != nil { audioPlayer!.dispose() }
            audioPlayer = nil
            audioSession.setCategory(AVAudioSessionCategoryAmbient, error: nil)
            userHasPressedPlay = false
            attemptedToQueueSongForCurrentSong = false
            movingFromInactiveToEmpty = false
            UIApplication.sharedApplication().endReceivingRemoteControlEvents()
            
        case .Empty:
            emptyStateTimeSinceLastGetNextSong = 0.0
            currentSong = nil
            movingFromInactiveToEmpty = false
            attemptedToQueueSongForCurrentSong = false
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            partyManager.clearSongInfo()
            getNextSong()
            
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
        stateTime += StateServicePeriod
        timeSinceLastSongAdded += StateServicePeriod
        let partyManager = PartyManager.sharedParty
        
        switch state {
        case .Inactive:
            if partyManager.state == .HostStreamable && !movingFromInactiveToEmpty {
                onUserBecameHostStreamable()
                return
            }
            
        case .Empty:
            emptyStateTimeSinceLastGetNextSong += StateServicePeriod
            
            if partyManager.state != .HostStreamable { onUserNoLongerHostStreamable(); return }
            if !AFNetworkReachabilityManager.sharedManager().reachable { onNetworkNotReachable(); return }
            
            if audioPlayerStateIsPlayingAndShouldCallEvent() {
                audioPlayer!.stop()
                setState(.Empty)
                return
            }
            
            // Got next song
            if partyManager.hasCurrentSongAndUser {
                currentSong = partyManager.currentSong
                timeSinceLastSongAdded = 0.0
                playCurrentSong()
                
                if userHasPressedPlay {
                    setState(.Playing)
                    return
                } else {
                    setState(.Paused)
                    return
                }
                
            } else if emptyStateTimeSinceLastGetNextSong > EmptyStateGetNextSongRefreshPeriod {
                emptyStateTimeSinceLastGetNextSong = 0.0
                getNextSong()
            }
            
        case .Paused:
            if partyManager.state != .HostStreamable { onUserNoLongerHostStreamable(); return }
            if !partyManager.hasCurrentSongAndUser { onPartyNoLongerHasCurrentSong(); return }
            if !AFNetworkReachabilityManager.sharedManager().reachable { onNetworkNotReachable(); return }
            if currentSongIsMismatched() { onCurrentSongMismatch(); return }
            if audioPlayerStateIsNotRunningAndShouldCallEvent() { onAudioPlayerNoLongerRunning(); return }
            
        case .Playing:
            playingStateTimeSinceLastMPNowPlayingRefresh += StateServicePeriod
            
            if partyManager.state != .HostStreamable { onUserNoLongerHostStreamable(); return }
            if !partyManager.hasCurrentSongAndUser { onPartyNoLongerHasCurrentSong(); return }
            if !AFNetworkReachabilityManager.sharedManager().reachable { onNetworkNotReachable(); return }
            if currentSongIsMismatched() { onCurrentSongMismatch(); return }
            if audioPlayerStateIsNotRunningAndShouldCallEvent() { onAudioPlayerNoLongerRunning(); return }

            let progress = audioPlayer!.progress // Number of seconds into the song
            let duration = audioPlayer!.duration // Song length in seconds
            
            if duration < 0.01 {
                // "in between" songs; duration is 0
                partyManager.delegate.updateCurrentSongProgress(0.0)
            } else {
                let progressPercent = Float(progress / duration)
                partyManager.delegate.updateCurrentSongProgress(progressPercent)
                
                // Try queueing the next song
                let timeRemaining = duration - progress
                if timeRemaining < SongTimeRemainingToQueueNextSong && !attemptedToQueueSongForCurrentSong {
                    attemptedToQueueSongForCurrentSong = true
                    queueNextSong()
                }
                
                // Refresh the MPNowPlayingInfo
                if playingStateTimeSinceLastMPNowPlayingRefresh < PlayingStateMPNowPlayingRefreshPeriod {
                    playingStateTimeSinceLastMPNowPlayingRefresh = 0.0
                    partyManager.updateMPNowPlayingInfoCenterInfo(elapsedTime: progress)
                }
            }
        }
    }
    
    // Play the current song, have it's playAttempts incremented (through getExternalIDForPlaying)
    private func playCurrentSong() {
        if let song = currentSong {
            let songToPlay = SCClient.sharedClient.getSongURLString(currentSong!.getExternalIDForPlaying())
            audioPlayer!.play(songToPlay)
            postPartyCurrentSongChangeUpdates()
        }
    }
    
    // Returns true when audioPlayer is playing and the grace periods have been passed
    func audioPlayerStateIsPlayingAndShouldCallEvent() -> Bool {
        return audioPlayerStateIsPlaying() && stateTime > StateTimeGracePeriod && timeSinceLastSongAdded > TimeSinceLastSongAddedGracePeriod
    }
    
    // Returns true when audioPlayer is not running, the grace periods have been passed, and the time remaining for the current song (if it exists) isn't within the time span where the next song could be queued
    func audioPlayerStateIsNotRunningAndShouldCallEvent() -> Bool {
        return audioPlayerStateIsNotRunning() && (stateTime > StateTimeGracePeriod) &&
            (timeSinceLastSongAdded > TimeSinceLastSongAddedGracePeriod) && !currentSongTimeRemainingWithinQueueTimeSpan()
    }
    
    func onPlayButton() {
        if state != .Inactive {
            userHasPressedPlay = true
            setState(.Playing)
        }
    }
    
    func onPauseButton() {
        if state != .Inactive { setState(.Paused) }
    }
    
    func onSongSkip() {
        if hasAudio {
            songWasSkipped = true
            
            // Only seek if the song isn't already within the queueing time span from the end
            if !currentSongTimeRemainingWithinQueueTimeSpan() {
                
                let progress = audioPlayer!.progress // Number of seconds into the song
                let duration = audioPlayer!.duration // Song length in seconds
                let timeRemaining = duration - progress
                
                // Give serviceState() enough time to try queueing the next song
                audioPlayer!.seekToTime(duration - StateServicePeriod * 3)
            }
            
            // Play out the rest
            if state == .Paused {
                // If it's paused, make it play
                setState(.Playing)
            }
            // If it's playing it will continue to play out the song
            
            // Skipping the song will then either take < the queueTimeSpan, or stateServicePeriod * 3 seconds
        }
    }
    
    /*
    func onSongSkip() {
        if hasAudio {
            // Only skip if the song isn't already playing AND (close enough to the end to queue the next one OR close enough to the start that this is the song that could've been queued)
            if !(state == .Playing && currentSongTimeRemainingWithinQueueTimeSpan() || currentSongProgressWithinQueueTimeSpan()) {
                
                // If the actual progress bar's progress is within the queue time
                if partyCurrentSongProgressBarTimeRemainingWithinQueueTime() {
                    // If it's paused, then just play it out
                    if state == .Paused {
                        setState(.Playing)
                    }
                    // If it's playing then do nothing, let it continue to play out
                } else {
                    songWasSkipped = true
                    
                    let progress = audioPlayer!.progress // Number of seconds into the song
                    let duration = audioPlayer!.duration // Song length in seconds
                    let timeRemaining = duration - progress
                    
                    // Give serviceState() enough time to try queueing the next song
                    audioPlayer!.seekToTime(duration - stateServicePeriod * 3)
                }
            }
        }
    }
    */
    
    private func onSongFinishedWithNoQueuedSong() {
        // Must check if inactive, because this will get called when playing a song and losing HostStreamable,
        // except usually AFTER the state has already been set to inactive
        if state != .Inactive { setState(.Empty) }
    }
    
    // Only call this after PartyManager's currentSong is changed to its queuedSong
    private func onSongFinishedWithQueuedSong() {
        currentSong = PartyManager.sharedParty.currentSong
        timeSinceLastSongAdded = 0.0
        postPartyCurrentSongChangeUpdates()
    }
    
    private func onPartyNoLongerHasCurrentSong() {
        if state != .Inactive { setState(.Empty) }
    }
    
    private func onGotNextSongPlayAlreadyPressed() {
        if state != .Inactive { setState(.Playing) }
    }
    
    private func onGotNextSongPlayNotAlreadyPressed() {
        if state != .Inactive { setState(.Paused) }
    }
    
    // The audio manager's current song doesn't match the party manager's current song
    private func onCurrentSongMismatch() {
        audioPlayer!.stop()
        setState(.Empty)
    }
    
    // Audio player isn't in Running state when it should be playing or paused
    private func onAudioPlayerNoLongerRunning() {
        setState(.Empty)
    }
    
    private func onUserBecameHostStreamable() {
        if initializeAudioSessionForPlaying() {
            initializeAudioPlayerForPlaying()
            movingFromInactiveToEmpty = true
            delayOnMainQueueFor(numberOfSeconds: 0.3, action: {
                // Give some time to be initialized
                self.setState(.Empty)
            })
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
        if state != .Inactive { setState(.Paused) }
    }
    
    private func onAudioInterruptionEndedShouldResume() {
        if state != .Inactive { setState(.Playing) }
    }
    
    private func onAudioOutputChange() {
        if state == .Playing { setState(.Paused) }
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
            // Let getNextSong get called immediately
            if emptyStateTimeSinceLastGetNextSong > 0.5 {
                emptyStateTimeSinceLastGetNextSong = EmptyStateGetNextSongRefreshPeriod
            }
        }
    }
    
    func resetEmptyStateTimeSinceLastGetNextSong() {
        emptyStateTimeSinceLastGetNextSong = 0.0
    }
    
    private func getNextSong() {
        PartyManager.sharedParty.getNextSong(songWasSkipped)
        songWasSkipped = false
    }
    
    private func queueNextSong() {
        PartyManager.sharedParty.queueNextSong(songWasSkipped, completion: {
            let queueSongID = PartyManager.sharedParty.queueSong?.getExternalIDForPlaying()
            if queueSongID != nil {
                let songToQueue = SCClient.sharedClient.getSongURLString(queueSongID!)
                self.audioPlayer!.queue(songToQueue)
            }
        })
        songWasSkipped = false
    }
    
    private func currentSongIsMismatched() -> Bool {
        // Make sure the party has had proper time to refresh the info
        if audioPlayer!.progress > (PartyManager.sharedParty.GetCurrentPartyRefreshPeriod + 2) {
            // Song can be mismatched when queueing the next one, make sure it's not for that reason
            if (audioPlayer!.duration - audioPlayer!.progress) > (SongTimeRemainingToQueueNextSong + 2) {
                if currentSong != PartyManager.sharedParty.currentSong { return true }
            }
        }
        return false
    }
    
    // Returns true if audioPlayer exists and its state is Playing
    private func audioPlayerStateIsPlaying() -> Bool {
        return audioPlayer != nil && audioPlayer!.state == STKAudioPlayerStatePlaying
    }
    
    // Returns true if audioPlayer exists and its state is not Running
    private func audioPlayerStateIsNotRunning() -> Bool {
        if audioPlayer != nil {
            // Bitwise AND the state with Running. If the result is 0, then the audio player is not Running
            // See the STKAudioPlayerState declaration to understand
            if (audioPlayer!.state.value & STKAudioPlayerStateRunning.value) == 0 {
                return true
            }
        }
        return false
    }
    
    // Returns true if current song time remaining is within timespan of where the next song could have been queued
    private func currentSongTimeRemainingWithinQueueTimeSpan() -> Bool {
        let progress = audioPlayer!.progress // Number of seconds into the song
        let duration = audioPlayer!.duration // Song length in seconds
        let timeRemaining = duration - progress
        let queueTimeSpan = SongTimeRemainingToQueueNextSong + 1
        return currentSong != nil && timeRemaining < queueTimeSpan || duration < queueTimeSpan
    }
    
    private func initializeAudioSessionForPlaying() -> Bool {
        // Setup audio session
        audioSession = AVAudioSession.sharedInstance()
        
        var setBufferDurationError = NSErrorPointer()
        var success1 = audioSession.setPreferredIOBufferDuration(0.1, error: setBufferDurationError)
        if !success1 {
            // println("not successful 1")
            if setBufferDurationError != nil {
                // println("ERROR with set buffer")
                // println(setBufferDurationError)
            }
        }
        
        var setCategoryError = NSErrorPointer()
        var success2 = audioSession!.setCategory(AVAudioSessionCategoryPlayback, error: setCategoryError)
        if !success2 {
            // println("not successful 2")
            if setCategoryError != nil {
                // println("ERROR with set category")
                // println(setCategoryError)
            }
        }
        
        var activationError = NSErrorPointer()
        var success3 = audioSession!.setActive(true, error: activationError)
        if !success3 {
            // println("not successful 3")
            if activationError != nil {
                // println("ERROR with set active")
                // println(activationError)
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
    
    private func disposeAudioPlayer() {
        audioPlayer?.dispose()
        audioPlayer = nil
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
        
        // Current song ended with less than 0.1 seconds when streaming
        if partyManager.state == .HostStreamable && progress < 0.1 && currentSong != nil {
            
            // Try playing the song again
            if currentSong!.playAttempts <= MaxSongPlayAttempts {
                playCurrentSong()
            
            // Song was most likely unstreamable if finished playing with such small amt of time and still not playing
            // after a couple attempts
            } else {
                var songInfo = ""
                if let currentSongName = currentSong?.name {
                    if let currentSongArtist = currentSong?.artistName {
                        songInfo = "'\(currentSongName)' uploaded by '\(currentSongArtist)' "
                    } else {
                        songInfo = "'\(currentSongName)' "
                    }
                }
                
                let alertMessage = "The SoundCloud song \(songInfo)being played could not be streamed. To play this song, try searching for a different version of it, or getting it from a different uploader"
                let alert = UIAlertView(title: "Unstreamable Song Skipped", message: alertMessage, delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.tag = AlertTag.UnstreamableSongSkipped.rawValue
                AlertManager.sharedManager.showAlert(alert)
                
                disposeAudioPlayer()
                initializeAudioSessionForPlaying()
                initializeAudioPlayerForPlaying() // Fix for randomly not working?
                setState(.Empty)
            }
            
            return
        }
        
        partyManager.delegate.updateCurrentSongProgress(0.0)
        
        // If there's a queued song
        if partyManager.setQueueSongAndUserToCurrent() {
            onSongFinishedWithQueuedSong()
        } else {
            onSongFinishedWithNoQueuedSong()
        }
    }
    
    // Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlayer)
    func audioPlayer(audioPlayer: STKAudioPlayer!, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        disposeAudioPlayer()
        initializeAudioSessionForPlaying()
        initializeAudioPlayerForPlaying()
        setState(.Empty)
    }
}

extension PartyAudioManager {
    // MARK: handling AVAudioSession notifications
    
    func handleAudioSessionInterruption(n: NSNotification) {
        if n.name != AVAudioSessionInterruptionNotification || n.userInfo == nil
            || PartyManager.sharedParty.state != .HostStreamable { return }
        
        // println("AVAudioSessionInterruptionNotification")
        var info = n.userInfo!
        var interruptionTypeValue: UInt = 0
        (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&interruptionTypeValue)
        if let type = AVAudioSessionInterruptionType(rawValue: interruptionTypeValue) {
            switch type {
            case .Began:
                // Audio has stopped, already inactive
                // Change state of UI, etc., to reflect non-playing state
                // println("began")
                onAudioInterruptionBegan()
            case .Ended:
                // Make session active
                // Update user interface
                // println("ended")
                var interruptionOptionValue: UInt = 0
                (info[AVAudioSessionInterruptionOptionKey] as! NSValue).getValue(&interruptionOptionValue)
                let option = AVAudioSessionInterruptionOptions(rawValue: interruptionOptionValue)
                if option == AVAudioSessionInterruptionOptions.OptionShouldResume {
                    // AVAudioSessionInterruptionOptionShouldResume option
                    // Here you should continue playback
                    onAudioInterruptionEndedShouldResume()
                }
            }
        }
    }
    
    // Used to pause audio when output cord unplugged
    func handleAVAudioSessionRouteChangeNotification(n: NSNotification) {
        if n.name != AVAudioSessionRouteChangeNotification || n.userInfo == nil
            || PartyManager.sharedParty.state != .HostStreamable { return }
        
        // println("AVAudioSessionRouteChangeNotification")
        var info = n.userInfo!
        var routeChangeTypeValue: UInt = 0
        (info[AVAudioSessionRouteChangeReasonKey] as! NSValue).getValue(&routeChangeTypeValue)
        if let routeChangeReason = AVAudioSessionRouteChangeReason(rawValue: routeChangeTypeValue) {
            if routeChangeReason == AVAudioSessionRouteChangeReason.OldDeviceUnavailable {
                onAudioOutputChange()
            }
        }
    }
    
    // Apple: "Responding to a Media Server Reset"
    // Apple says it's rare but can happen
    func handleMediaServicesReset() {
        onMediaServicesReset()
    }
}