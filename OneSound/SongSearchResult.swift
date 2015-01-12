//
//  SongSearchResult.swift
//  OneSound
//
//  Created by adam on 8/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SongSearchResult {
    
    private(set) var source: String!
    private(set) var externalID: Int!
    private(set) var artworkURL: String?
    
    // Data to display
    private(set) var name: String!
    private(set) var artistName: String!
    private(set) var duration: Int!
    private(set) var numberOfPlaybacks: Int?
    
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
