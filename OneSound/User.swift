//
//  User.swift
//  OneSound
//
//  Created by adam on 7/8/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

enum UserColors: String {
    case Green = "g"
    case Turquoise = "t"
    case Purple = "p"
    case Red = "r"
    case Orange = "o"
    case Yellow = "y"
}

let numberOfOneSoundColors = 6

class User {
   
    var id: Int!
    var name: String!
    var color: String!
    var guest: Bool!
    var photo: String?
    var songCount: Int!
    var voteCount: Int!
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
        photo = json["photo"].string
        songCount = json["song_count"].integer
        voteCount = json["vote_count"].integer
        followers = json["followers"].integer
        following = json["following"].integer
    }
    
    func description() -> String {
        return "[USER] id:\(id) name:'\(name)' color:\(color) guest:\(guest) f-ers:\(followers) f-ing:\(following) songs:\(songCount) votes:\(voteCount) photo:\(photo)"
    }
    
}
