//
//  Song.swift
//  OneSound
//
//  Created by adam on 7/31/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

enum UserSongVote: Int {
    case Down = -1
    case None = 0
    case Up = 1
}

class Song {
    var songID: Int!
    var source: String!
    private var externalID: Int!
    var userID: Int!
    var partyID: Int!
    
    // Display data
    var name: String!
    var artistName: String!
    var duration: Int! // Song duration in seconds
    var artworkURL: String?
    var userVote: UserSongVote?
    var voteCount: Int!
    
    var playAttempts = 0
    
    
    func getExternalIDForPlaying() -> Int! {
        ++playAttempts
        return externalID
    }
    
    init(json: JSONValue) {
        songID = json["sid"].integer
        source = json["source"].string
        externalID = json["external_id"].integer
        userID = json["user_uid"].integer
        
        name = json["title"].string
        artistName = json["artist"].string
        duration = json["length"].integer
        artworkURL = json["album"].string
        voteCount = json["vote_count"].integer
        
        if let vote = json["user_vote"].integer {
            userVote = UserSongVote(rawValue: vote)
        }
    }
}

extension Song: Equatable { }
// MARK: Equatable
func == (lhs: Song, rhs: Song) -> Bool {
    return lhs.externalID == rhs.externalID && lhs.userID == rhs.userID
}
