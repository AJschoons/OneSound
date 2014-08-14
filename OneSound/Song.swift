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
    
    // Stuff that comes from SoundCloud
    var name: String?
    var artistName: String?
    var duration: Int?
    var artworkURL: String?
    
    init(json: JSONValue) {
        songID = json["sid"].integer
        source = json["source"].string
        externalID = json["external_id"].integer
        voteCount = json["vote_count"].integer
        userID = json["uid"].integer
    }
}
