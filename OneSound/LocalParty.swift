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
    
    var songs = [Song?]()
    
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
    
    func joinAndOrRefreshParty(pid: Int, JSONUpdateCompletion: completionClosure? = nil, failureAddOn: completionClosure? = nil) {
        let user = LocalUser.sharedUser
        OSAPI.sharedClient.GETParty(pid, userID: user.id, userAPIToken: user.apiToken,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                
                self.updateMainPartyInfoFromJSON(responseJSON, JSONUpdateCompletion)
                self.updatePartyMembers(pid)
                //self.updatePartySongs(pid)
            },
            failure: { task, error in
                if failureAddOn != nil {
                    failureAddOn!()
                }
                defaultAFHTTPFailureBlock!(task: task, error: error)
            }
        )
    }
    
    func updatePartySongs(pid: Int) {
        OSAPI.sharedClient.GETPartyPlaylist(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                self.updatePartySongInfoFromJSON(responseJSON)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updatePartyMembers(pid: Int) {
        OSAPI.sharedClient.GETPartyMembers(pid,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                //self.updatePartySongInfoFromJSON(responseJSON)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    func updatePartySongInfoFromJSON(json: JSONValue) {
        songs.removeAll(keepCapacity: true)
        var songsToGet = true
        var i = 1
        while songsToGet {
            if let songDict = json["\(i)"].object {
                self.songs.insert(Song(json: json), atIndex: (i-1))
                i++
            } else {
                songsToGet = false
            }
        }
        println("UPDATED PARTY WITH \(self.songs.count) SONGS")
    }
    
    func updateMainPartyInfoFromJSON(json: JSONValue, completion: completionClosure? = nil) {
        setup = true
        
        partyID = json["pid"].integer
        isPrivate = json["privacy"].bool
        hostUserID = json["host"].integer
        name = json["name"].string
        strictness = json["strictness"].integer
    
        if completion != nil {
            completion!()
        }
    }
}
