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
   
    private(set) var id: Int!
    private(set) var name: String!
    private(set) var color: String!
    private(set) var guest: Bool!
    private(set) var photoURL: String?
    private(set) var songCount: Int!
    private(set) var upvoteCount: Int!
    private(set) var hotnessPercent: Int!
    private(set) var followers: Int!
    private(set) var following: Int!
    
    var colorToUIColor: UIColor {
        if let userColor = UserColors(rawValue: color) {
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
        return UIColor.clearColor()
    }
    
    init(json: JSON) {
        id = json["uid"].int
        name = json["name"].string
        color = json["color"].string
        guest = json["guest"].bool
        songCount = json["song_count"].int
        upvoteCount = json["vote_count"].int
        hotnessPercent = json["hotness"].int
        followers = json["followers"].int
        following = json["following"].int
        
        if guest == false && json["photo"].string != nil {
            // If not a guest and a non-empty photoURL gets sent that's different from what it was
            photoURL = json["photo"].string
        } else {
            // Guests and users w/o valid photo URL don't have photo URLs
            photoURL = nil
        }
    }
    /*
    func getUserPhoto(urlString: String) {
        self.photo!
        downloadImageWithURLString(urlString,
            { success, image in
                if success {
                    let smallestSide = (image!.size.height > image!.size.width) ? image!.size.width : image!.size.height
                    self.photo = cropBiggestCenteredSquareImageFromImage(image!, sideLength: smallestSide)
                    // println("Got new photo for user")
                }
            }
        )
    }
    */
    
    func description() -> String {
        return "[USER] id:\(id) name:'\(name)' color:\(color) guest:\(guest) f-ers:\(followers) f-ing:\(following) songs:\(songCount) votes:\(upvoteCount) photo:\(photoURL)"
    }
    
}
