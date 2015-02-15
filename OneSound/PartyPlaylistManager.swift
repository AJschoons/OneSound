//
//  PartyPlaylistManager.swift
//  OneSound
//
//  Created by adam on 12/28/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation

// A class to manage the party's playlist, with paging
class PartyPlaylistManager {
    
    var hasMorePages: Bool {
        return currentPage < totalPages
    }
    
    final private(set) var songs = [Song]() // Has to stay final to allow elements to be swapped
    // Used while updating so table still has something to show
    private var updatedSongs = [Song]()
    
    private var currentPage = 0
    
    private var totalPages: Int {
        return Int(ceil(Double(totalSongs) / Double(pageSize))) - 1
    }
    private var pageSize = 20 // Songs/Page
    private var totalSongs = 0
    
    private var updating = false
    
    // Increments the current page and adds the new data to updatedSongs
    func update(completion: completionClosure? = nil) {
        ++currentPage
        
        if !updating {
            updating = true
            
            let pageStartingFromZero = currentPage - 1
            OSAPI.sharedClient.GETPartyPlaylist(PartyManager.sharedParty.partyID, page: currentPage, pageSize: pageSize,
                success: { data, responseObject in
                    let responseJSON = JSON(responseObject)
                    //println(responseJSON)
                    
                    self.updatePlaylistFromJSON(responseJSON, completion: completion)
                },
                failure: defaultAFHTTPFailureBlock
            )
        }
    }
    
    // Resets all information to like new
    func reset() {
        songs = []
        totalSongs = 0
        clearForUpdate()
    }
    
    // Keeps the songs for displaying while updating
    func clearForUpdate() {
        updatedSongs = []
        currentPage = -1
        updating = false
    }
    
    func deleteSongAtIndex(index: Int, completion: completionClosure? = nil) {
        OSAPI.sharedClient.DELETESong(songs[index].songID,
            success: { data, responseObject in
                self.songs.removeAtIndex(index)
                if completion != nil { completion!() }
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    // Returns the new index
    func moveSongAtIndex(initialIndex: Int, afterChangingVoteCountBy voteCountChange: Int, withVote vote: SongVote) -> Int {
        let song = songs[initialIndex]
        let newVoteCount = song.voteCount + voteCountChange
        song.voteCount = newVoteCount
        song.userVote = vote
        var newIndex: Int
        
        // Song will be moved down in array
        if voteCountChange < 0 {
            newIndex = initialIndex
            // song.voteCount will now be less than the song before it
            while newIndex < (songs.count - 1) {
                if songs[newIndex + 1].voteCount > newVoteCount {
                    swap(&songs[newIndex], &songs[newIndex + 1])
                    ++newIndex
                } else {
                    break
                }
            }
            
        // Song will be moved up in array
        } else if voteCountChange > 0 {
            newIndex = initialIndex
            // song.voteCount will now be greater than the song before it
            while newIndex > 0 {
                if songs[newIndex - 1].voteCount < newVoteCount {
                    swap(&songs[newIndex - 1], &songs[newIndex])
                    --newIndex
                } else {
                    break
                }
            }
        
        // Song will stay in same place
        } else {
            newIndex = initialIndex
        }
        
        return newIndex
    }
    
    private func updatePlaylistFromJSON(json: JSON, completion: completionClosure? = nil) {
        
        totalSongs = json["paging"]["total_count"].int!
        
        var songsArray = json["results"].array
        var songsAdded = 0
        
        if songsArray != nil {
            songsAdded = songsArray!.count
            
            // If the page is zero, clears the array
            if currentPage == 0 { updatedSongs = [] }
            
            for song in songsArray! {
                updatedSongs.append(Song(json: song))
            }
        }
        
        songs = updatedSongs
        updating = false
        if completion != nil { completion!() }
        println("UPDATED PLAYLIST WITH \(songsAdded) SONGS OF THE \(self.songs.count)")
    }
    
}