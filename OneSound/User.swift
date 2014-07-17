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
    case Purple = "p"
    case Turquoise = "t"
    case Yellow = "y"
    case Red = "r"
    case Orange = "o"
}

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
    
    var apiToken: String?
    
    var soundCloudUID: String?
    var soundCloudAccessToken: String?
    
    var facebookUID: String?
    var facebookAccessToken: String?
    
    var twitterUID: String?
    var twitterAccessToken: String?
    
    var email: String?
    
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
        var d = "id:\(id) name:'\(name)' color:\(color) guest:\(guest) f-ers:\(followers) f-ing:\(following) songs:\(songCount) votes:\(voteCount) photo:\(photo) token:\(apiToken)"
        if facebookUID {
            d += " fUID:\(facebookUID)"
        }
        if facebookAccessToken {
            d += " fToken:\(facebookAccessToken)"
        }
        if twitterUID {
            d += " tUID:\(twitterUID)"
        }
        if twitterAccessToken {
            d += " tToken:\(twitterAccessToken)"
        }
        
        return d
    }
}
