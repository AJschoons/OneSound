//
//  Song.swift
//  OneSound
//
//  Created by adam on 7/31/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

enum PartySongVote: Int {
    case Down = -1
    case Clear = 0
    case Up = 1
}

class PartySong: Song {
    private(set) var userID: Int!
    private var externalID: String!
    
    // Display data
    private(set) var duration: Int! // Song duration in seconds
    var userVote: PartySongVote?
    var voteCount: Int!
    var isFavorited: Bool?
    
    private(set) var playAttempts = 0
    
    func getExternalIDForPlaying() -> String! {
        ++playAttempts
        return externalID
    }
    
    override init(json: JSON) {
        super.init(json: json)
        
        userID = json["user_uid"].int
        externalID = json["external_id"].string
        
        duration = json["length"].int
        voteCount = json["vote_count"].int
        
        if let vote = json["user_vote"].int {
            userVote = PartySongVote(rawValue: vote)
        }
        
        if let favorited = json["favorited"].bool {
            isFavorited = favorited
        }
    }
}

extension PartySong: Equatable { }
// MARK: Equatable
func == (lhs: PartySong, rhs: PartySong) -> Bool {
    if lhs.externalID != nil && rhs.externalID != nil && lhs.userID != nil && rhs.externalID != nil {
        return lhs.externalID == rhs.externalID && lhs.userID == rhs.userID
    } else {
        return false
    }
}
