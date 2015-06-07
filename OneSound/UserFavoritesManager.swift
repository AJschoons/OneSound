//
//  UserFavoritesManager.swift
//  OneSound
//
//  Created by adam on 6/6/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation


class UserFavoritesManager: PagedDataArrayManager
{
    typealias DataType = Song
    var pagedDataArray: PagedDataArray<Song>!
    
    func fetchDataPage(page: Int, usingFailureBlock failureBlock: AFHTTPFailureBlock, withCompletion completion: completionClosure?)
    {
        OSAPI.sharedClient.GETUserFavorites(UserManager.sharedUser.id,
            page: page,
            pageSize: pagedDataArray.pageSize,
            success: {[weak self] task, responseObject in
                if let strongSelf = self
                {
                    let responseJSON = JSON(responseObject)
                    println(responseJSON)
                    let dataSize = responseJSON["paging"]["total_count"].int!
                    
                    var favorites = [Song]()
                    if let favoritesJSON = responseJSON["results"].array {
                        for favoriteJSON in favoritesJSON {
                            favorites.append(Song(json: favoriteJSON))
                        }
                    }
                    
                    strongSelf.pagedDataArray.updateWithNewData(favorites, ofRemoteDataSize: dataSize, completion: completion)
                }
            },
            failure: failureBlock)
    }
    
    init() {
        pagedDataArray = PagedDataArray(manager: self)
    }
    
}