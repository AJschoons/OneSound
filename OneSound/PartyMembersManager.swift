//
//  PartyMembersManager.swift
//  OneSound
//
//  Created by adam on 12/30/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation

// A class to manage the party's members, with paging
class PartyMembersManager
{
    func hasMorePages() -> Bool { return currentPage < totalPages() }
    
    private(set) var users = [User]()
    // Used while updating so table still has something to show
    private var updatedUsers = [User]()
    
    private var currentPage = 0
    
    private func totalPages() -> Int {
        return Int(ceil(Double(totalUsers) / Double(pageSize))) - 1
    }
    private var pageSize = 20 // Songs/Page
    private var totalUsers = 0 
    
    private(set) var updating = false
    
    // Increments the current page and adds the new data to updatedSongs
    func update(completion: completionClosure? = nil) {
        ++currentPage
        
        if !updating {
            updating = true
            
            let pageStartingFromZero = currentPage - 1
            OSAPI.sharedClient.GETPartyMembers(PartyManager.sharedParty.partyID, page: currentPage, pageSize: pageSize,
                success: { data, responseObject in
                    let responseJSON = JSON(responseObject)
                    //println(responseJSON)
                    
                    self.updateMembersFromJSON(responseJSON, completion: completion)
                },
                failure: defaultAFHTTPFailureBlock
            )
        }
    }
    
    // Resets all information to like new
    func reset() {
        users = []
        totalUsers = 0
        clearForUpdate()
    }
    
    // Keeps the members for displaying while updating
    func clearForUpdate() {
        updatedUsers = []
        currentPage = -1
        updating = false
    }
    
    private func updateMembersFromJSON(json: JSON, completion: completionClosure? = nil) {
        totalUsers = json["paging"]["total_count"].int!
        
        var usersArray = json["results"].array
        var usersAdded = 0
        
        if usersArray != nil {
            usersAdded = usersArray!.count
            
            // If the page is zero, clears the array
            if currentPage == 0 { updatedUsers = [] }
            
            for user in usersArray! {
                updatedUsers.append(User(json: user))
            }
        }
        
        users = updatedUsers
        updating = false
        if completion != nil { completion!() }
        println("UPDATED MEMBERS WITH \(usersAdded) USERS OF THE \(self.users.count)")
    }
}