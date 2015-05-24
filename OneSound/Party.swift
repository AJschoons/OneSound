//
//  Party.swift
//  OneSound
//
//  Created by adam on 7/28/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class Party {
    private(set) var partyID: Int!
    private(set) var isPrivate: Bool!
    private(set) var isHost: Bool!
    private(set) var name: String!
    private(set) var strictness: Int!
    private(set) var memberCount: Int?
    private(set) var hostName: String?
    private(set) var distance: Double?
    
    init(json: JSON) {
        partyID = json["pid"].int
        isPrivate = json["privacy"].bool
        isHost = json["bool"].bool
        name = json["name"].string
        strictness = json["strictness"].int
        memberCount = json["member_count"].int
        hostName = json["host_name"].string
        distance = json["distance"].double
    }
}