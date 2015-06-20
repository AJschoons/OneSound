//
//  Songg.swift
//  OneSound
//
//  Created by adam on 6/7/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation

class Song {
    private(set) var songID: Int!
    private(set) var source: String!
    private(set) var partyID: Int!
    
    // Songs in the playlist and favories will have this, but not the current song
    private(set) var dateCreatedAt: NSDate?
    
    // Display data
    private(set) var name: String!
    private(set) var artistName: String!
    private(set) var artworkURL: String?
    
    init(json: JSON) {
        songID = json["sid"].int
        source = json["source"].string
        
        name = json["title"].string
        artistName = json["artist"].string
        artworkURL = json["album"].string
        
        // Songs in the playlist and favories will have this, but not the current song
        if let dateCreatedAtString = json["created_at"].string {
            dateCreatedAt = oneSoundDateFormatter.dateFromString(dateCreatedAtString)
        }
    }
}