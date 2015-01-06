//
//  SongSearchResult.swift
//  OneSound
//
//  Created by adam on 8/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SongSearchResult {
    
    var source: String!
    var externalID: Int!
    var artworkURL: String?
    
    // Data to displays
    var name: String!
    var artistName: String!
    var duration: Int!
    var numberOfPlaybacks: Int?
    
    init(source: String, externalID: Int, name: String, artistName: String, duration: Int, artworkURL: String?, numberOfPlaybacks: Int?) {
        self.source = source
        self.externalID = externalID
        self.name = name
        self.artistName = artistName
        self.duration = duration
        self.artworkURL = artworkURL
        self.numberOfPlaybacks = numberOfPlaybacks
    }
}
