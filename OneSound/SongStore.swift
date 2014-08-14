//
//  SongStore.swift
//  OneSound
//
//  Created by adam on 8/10/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SongStore: NSObject {
    
    class var sharedStore: SongStore {
    struct Singleton {
        // lazily initiated, thread-safe from "let"
        static let instance = SongStore()
        }
        return Singleton.instance
    }
    
    var songsWithAudioBeingDownloaded = SwiftSet<Int>()
    var songsWithAttributesBeingDownloaded = SwiftSet<Int>()
    
    var _privateSongAudioDictionary = Dictionary<Int, NSData>()
    var allSongAudioData: Dictionary<Int, NSData> {
        return _privateSongAudioDictionary
    }
    
    var _privateSongDictionary = Dictionary<Int, Song>()
    var allSongs: Dictionary<Int, Song> {
        return _privateSongDictionary
    }
    
    override init() {
        super.init()
        
        // Register the songStore to receive memory warning notifications
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "clearSongCacheAndSongAudioCache:", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        
        delayOnMainQueueFor(numberOfSeconds: 0.1, action: {
            assert(self === SongStore.sharedStore, "Created non-Singleton SongStore. Use SongStore.sharedStore")
        })
    }
    
    func setSong(song: Song, forKey key: Int) {
        _privateSongDictionary.updateValue(song, forKey: key)
    }
    
    func setSongAudio(audio: NSData, forKey key: Int) {
        _privateSongAudioDictionary.updateValue(audio, forKey: key)
    }
    
    func songInformationForSong(inout song: Song, completion: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        let key = song.songID
        
        // If possible, get it from the dictionary
        var result = _privateSongDictionary[key]
        
        if result == nil {
            println("song not cached, need to download its attributes")
            if songsWithAttributesBeingDownloaded.contains(key) {
                println("song attributes are already being downloaded")
            } else {
                songsWithAttributesBeingDownloaded.add(key)
                
                SCClient.sharedClient.getSoundCloudSongByID(key,
                    success: {data, responseObject in
                        let responseJSON = JSONValue(responseObject)
                        //println(responseJSON)
                        let SCSongName = responseJSON["title"].string
                        let SCUserName = responseJSON["user"]["username"].string
                        let SCSongDuration = responseJSON["duration"].integer
                        var SCArtworkURL = responseJSON["artwork_url"].string
                        
                        if SCArtworkURL != nil {
                            SCArtworkURL = SCArtworkURL!.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")
                            song.artworkURL = SCArtworkURL
                        }
                        if SCSongName != nil {
                            song.name = SCSongName
                        }
                        if SCUserName != nil {
                            song.artistName = SCUserName
                        }
                        if SCSongDuration != nil {
                            song.duration = SCSongDuration
                        }
                        
                        self._privateSongDictionary.updateValue(song, forKey: key)
                        
                        if completion != nil {
                            completion!()
                        }
                    },
                    failure: { task, error in
                        self.songsWithAttributesBeingDownloaded.remove(key)
                        if failureAddOn != nil {
                            failureAddOn!()
                        }
                        defaultAFHTTPFailureBlock!(task: task, error: error)
                    }
                )
            }
        } else {
            song = result!
            songsWithAttributesBeingDownloaded.remove(key)
            if completion != nil {
                completion!()
            }
        }
    }
    
    func songAudioForKey(key: Int, completion: (NSData?) -> () ) {
        // If possible, get it from the dictionary
        var result = _privateSongAudioDictionary[key]
        
        if result == nil {
            println("song AUDIO not cached, need to download it")
            if songsWithAudioBeingDownloaded.contains(key) {
                println("song AUDIO is already being downloaded")
            } else {
                songsWithAudioBeingDownloaded.add(key)
                SCClient.sharedClient.downloadSoundCloudSongData(key,
                    completion: { data, response, error in
                        if !error {
                            completion(data)
                            // If the song downloads w/o an error then cache it
                            self._privateSongAudioDictionary.updateValue(data, forKey: key)
                            // Make the party refresh after the song is completed downloading
                            LocalParty.sharedParty.refresh()
                        } else {
                            completion(nil)
                        }
                        self.songsWithAudioBeingDownloaded.remove(key)
                    }
                )
            }
        } else {
            songsWithAudioBeingDownloaded.remove(key)
            completion(result)
        }
    }
    
    func deleteSongForKey(key: Int) {
        _privateSongDictionary.removeValueForKey(key)
    }
    
    func deleteSongAudioForKey(key: Int) {
        _privateSongAudioDictionary.removeValueForKey(key)
    }
    
    func clearSongInformationCache() {
        // Removes all instances of Songs from the SongStore's dictionary
        println("Flushing \(_privateSongDictionary.count) songs out of the cache")
        _privateSongDictionary.removeAll(keepCapacity: false)
    }
    
    func clearSongAudioCache() {
        // Removes all instances of NSData from the SongStore's dictionary
        println("Flushing \(_privateSongAudioDictionary.count) song audio out of the cache")
        _privateSongAudioDictionary.removeAll(keepCapacity: false)
    }
    
    func clearSongCacheAndSongAudioCache(note: NSNotification) {
        // All the songs lose an owner when removed from the Dictionary. Songs
        // not being used by other objects are destroyed and will be reloaded from
        // the filesystem when needed.
        // If a song is being used it won't be destroyed until it is finished
        clearSongInformationCache()
        clearSongAudioCache()
    }
}