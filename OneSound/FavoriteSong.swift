//
//  FavoriteSong.swift
//  OneSound
//
//  Created by adam on 6/7/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation

class FavoriteSong: Song {
    private(set) var externalID: String!
    
    override init(json: JSON) {
        super.init(json: json)
        
        externalID = json["external_id"].string
    }
}