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
    private var externalID: String! // Use getters, and only getExternalIDForPlaying in AudioManager
    private(set) var dateCreatedAt: NSDate? // Optional because // Songs in the playlist will have this, but not the current song
    
    // Display data
    private(set) var name: String!
    private(set) var artistName: String!
    private(set) var duration: Int! // Song duration in seconds
    private(set) var artworkURL: String?
    var userVote: SongVote?
    var voteCount: Int!
    var isFavorited: Bool?
    
    private(set) var playAttempts = 0
    
    func getExternalIDForPlaying() -> String! {
        ++playAttempts
        return externalID
    }
    
    init(json: JSON) {
        songID = json["sid"].int
        source = json["source"].string
        externalID = json["external_id"].string
        userID = json["user_uid"].int
        
        name = json["title"].string
        artistName = json["artist"].string
        duration = json["length"].int
        artworkURL = json["album"].string
        voteCount = json["vote_count"].int
        
        if let vote = json["user_vote"].int {
            userVote = SongVote(rawValue: vote)
        }
        
        // Songs in the playlist will have this, but not the current song
        if let dateCreatedAtString = json["created_at"].string {
            dateCreatedAt = oneSoundDateFormatter.dateFromString(dateCreatedAtString)
        }
        
        if let favorited = json["favorited"].bool {
            isFavorited = favorited
        }
    }
}

extension Song: Equatable { }
// MARK: Equatable
func == (lhs: Song, rhs: Song) -> Bool {
    if lhs.externalID != nil && rhs.externalID != nil && lhs.userID != nil && rhs.externalID != nil {
        return lhs.externalID == rhs.externalID && lhs.userID == rhs.userID
    } else {
        return false
    }
}
