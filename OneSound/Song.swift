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
    
    init(json: JSONValue) {
        songID = json["sid"].integer
        source = json["source"].string
        externalID = json["external_id"].integer
        voteCount = json["vote_count"].integer
        if let uid = json["uid"].integer {
            userID = uid
        } else {
            // defaults to my account (for now)
            userID = 61
        }
        if let pid = json["pid"].integer {
            partyID = pid
        } else {
            // defaults to the first party (for now)
            partyID = 0
        }
    }
}
