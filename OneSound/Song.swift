//
//  Song.swift
//  OneSound
//
//  Created by adam on 7/31/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class Song {
    var songID: Int!
    var source: String!
    var externalID: Int!
    var voteCount: Int!
    var userID: Int!
    var partyID: Int!
    
    // Display data
    var name: String!
    var artistName: String!
    var duration: Int!
    var artworkURL: String?
    
    init(json: JSONValue) {
        songID = json["sid"].integer
        source = json["source"].string
        externalID = json["external_id"].integer
        voteCount = json["vote_count"].integer
        userID = json["uid"].integer
        
        name = json["title"].string
        artistName = json["artist"].string
        duration = json["length"].integer
        artworkURL = json["album"].string
    }
}
