//
//  LocalParty.swift
//  OneSound
//
//  Created by adam on 7/28/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class LocalParty {
    
    var partyID: Int!
    var isPrivate: Bool!
    var hostUserID: Int?
    var name: String!
    var strictness: Int!
    
    var setup = false
    
    class var sharedParty: LocalParty {
    struct Static {
        static let localParty = LocalParty()
        }
        return Static.localParty
    }
}

extension LocalParty {
    // MARK: Party networking related code for user's active party
    
    func joinAndOrRefreshParty(pid: Int) {
        let user = LocalUser.sharedUser
        OSAPI.sharedClient.GETParty(pid, userID: user.id, userAPIToken: user.apiToken,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                
                self.updateMainPartyInfoFromJSON(responseJSON)
                //self.updatePartySongs(pid)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updatePartySongs(pid: Int) {
        OSAPI.sharedClient.GETPartyPlaylist(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updatePartySongInfoFromJSON(json: JSONValue) {
        
    }
    
    func updateMainPartyInfoFromJSON(json: JSONValue) {
        setup = true
        
        partyID = json["pid"].integer
        isPrivate = json["privacy"].bool
        hostUserID = json["host"].integer
        name = json["name"].string
        strictness = json["strictness"].integer
    }
}
