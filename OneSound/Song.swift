//
//  Song.swift
//  OneSound
//
//  Created by adam on 7/31/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

enum SongVote: Int {
    case Down = -1
    case Clear = 0
    case Up = 1
}

class Song {
    private(set) var songID: Int!
    private(set) var source: String!
    private(set) var userID: Int!
    private(set) var partyID: Int!
    private var externalID: Int! // Use getters, and only getExternalIDForPlaying in AudioManager
    
    // Display data
    private(set) var name: String!
    private(set) var artistName: String!
    private(set) var duration: Int! // Song duration in seconds
    private(set) var artworkURL: String?
    private(set) var userVote: SongVote?
    var voteCount: Int!
    
    private var playAttempts = 0
    
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
            userVote = SongVote(rawValue: vote)
        }
    }
}

extension Song: Equatable { }
// MARK: Equatable
func == (lhs: Song, rhs: Song) -> Bool {
    return lhs.externalID == rhs.externalID && lhs.userID == rhs.userID
}
