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
    
    var songsBeingDownloaded = SwiftSet<Int>()
    
    // Common design pattern for a class that wants strict control over its
    // internal data:
    // Internally, SongStore needs to be able to mutate the dictionary and set
    // or remove entries
    var _privateDictionary = Dictionary<Int, NSData>()
    // The allsongs property can't be changed by other objects
    var allSongs: Dictionary<Int, NSData> {
        return _privateDictionary
    }
    
    override init() {
        super.init()
        
        // Register the songStore to receive memory warning notifications
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "clearCache:", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        
        delayOnMainQueueFor(numberOfSeconds: 0.1, action: {
            assert(self === SongStore.sharedStore, "Created non-Singleton SongStore. Use SongStore.sharedStore")
        })
    }
    
    func setSong(song: NSData, forKey key: Int) {
        _privateDictionary.updateValue(song, forKey: key)
    }
    
    func songForKey(key: Int, completion: (NSData?) -> () ) {
        // If possible, get it from the dictionary
        var result = _privateDictionary[key]
        
        if result == nil {
            println("song not cached, need to download it")
            if songsBeingDownloaded.contains(key) {
                println("song is already being downloaded")
            } else {
                songsBeingDownloaded.add(key)
                SCClient.sharedClient.downloadSoundCloudSongData(key,
                    completion: { data, response, error in
                        if !error {
                            completion(data)
                            // If the song downloads w/o an error then cache it
                            self._privateDictionary.updateValue(data, forKey: key)
                        } else {
                            completion(nil)
                        }
                        self.songsBeingDownloaded.remove(key)
                    }
                )
            }
        } else {
            completion(result)
            songsBeingDownloaded.remove(key)
        }
    }
    
    func deleteSongForKey(key: Int) {
        _privateDictionary.removeValueForKey(key)
    }
    
    func clearCache(note: NSNotification) {
        // Removes all instances of NSData from the SongStore's dictionary
        println("Flushing \(_privateDictionary.count) songs out of the cache")
        
        // All the songs lose an owner when removed from the Dictionary. Songs
        // not being used by other objects are destroyed and will be reloaded from
        // the filesystem when needed.
        // If a song is being used it won't be destroyed until it is finished
        _privateDictionary.removeAll(keepCapacity: false)
    }
}