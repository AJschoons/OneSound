//
//  User.swift
//  OneSound
//
//  Created by adam on 7/8/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let numberOfOneSoundColors = 6

class User {
   
    var id: Int!
    var name: String!
    var color: String!
    var guest: Bool!
    var photoURL: String?
    var songCount: Int!
    var upvoteCount: Int!
    var followers: Int!
    var following: Int!
    
    var colorToUIColor: UIColor {
        if let userColor = UserColors.fromRaw(color) {
            switch userColor {
            case .Green:
                return UIColor.green()
            case .Purple:
                return UIColor.purple()
            case .Turquoise:
                return UIColor.turquoise()
            case .Yellow:
                return UIColor.yellow()
            case .Red:
                return UIColor.red()
            case .Orange:
                return UIColor.orange()
            }
        }
        return UIColor.brownColor()
    }
    
    init(json: JSONValue) {
        id = json["uid"].integer
        name = json["name"].string
        color = json["color"].string
        guest = json["guest"].bool
        photoURL = json["photo"].string
        songCount = json["song_count"].integer
        upvoteCount = json["vote_count"].integer
        followers = json["followers"].integer
        following = json["following"].integer
    }
    
    func description() -> String {
        return "[USER] id:\(id) name:'\(name)' color:\(color) guest:\(guest) f-ers:\(followers) f-ing:\(following) songs:\(songCount) votes:\(upvoteCount) photo:\(photoURL)"
    }
    
}
