//
//  Party.swift
//  OneSound
//
//  Created by adam on 7/28/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class Party {
    var partyID: Int!
    var isPrivate: Bool!
    var hostUserID: Int?
    var name: String!
    var strictness: Int!
    var memberCount: Int?
    var hostName: String?
    
    init(json: JSONValue) {
        partyID = json["pid"].integer
        isPrivate = json["privacy"].bool
        hostUserID = json["host"].integer
        name = json["name"].string
        strictness = json["strictness"].integer
        memberCount = json["member_count"].integer
        hostName = json["host_name"].string
    }
}