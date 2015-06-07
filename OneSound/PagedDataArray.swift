//
//  PagedDataManager.swift
//  OneSound
//
//  Created by adam on 6/5/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation

protocol PagedDataArrayManager: class {
    func fetchDataPage(page: Int, usingFailureBlock failureBlock: AFHTTPFailureBlock, withCompletion completion: completionClosure?)
}

// A generic array to be used with paged data
class PagedDataArray<T> {
    
    var updating = false
    
    init(manager: PagedDataArrayManager) {
        self.manager = manager
    }
    
    weak private var manager: PagedDataArrayManager!
    
    func hasMorePages() -> Bool { return currentPage < totalPages() }
    
    private(set) var data = [T]()
    
    // Used while updating so data array has something to show for any displayer
    private var updatedData = [T]()
    
    private var currentPage = 0
    
    private func totalPages() -> Int {
        return Int(ceil(Double(remoteDataSize) / Double(pageSize))) - 1
    }
    
    // Data/Page
    private(set) var pageSize = 20
    
    // Total number of data held remotely
    private var remoteDataSize = 0
    
    // Increments the current page and adds the new data to updateData
    func fetchNextPage(completion: completionClosure? = nil) {
        ++currentPage
        let currentPageeee = currentPage
        
        if !updating {
            updating = true
            
            //let pageStartingFromZero = currentPage - 1
            manager.fetchDataPage(currentPage, usingFailureBlock: getPagedDataFetchFailureBlock(), withCompletion: completion)
        }
    }
    
    // Resets all information to like new
    func reset() {
        data = []
        remoteDataSize = 0
        clearForUpdate()
    }
    
    // Keeps the members for displaying while updating
    func clearForUpdate() {
        updatedData = []
        currentPage = -1
        updating = false
    }
    
    func updateWithNewData(newData: [T]?, ofRemoteDataSize size: Int, completion: completionClosure? = nil) {
        remoteDataSize = size
        
        // If the page is zero, clears the updatedData array
        if currentPage == 0 { updatedData = [] }
        
        if newData != nil {
            for dataItem in newData! {
                updatedData.append(dataItem)
            }
        }
        
        data = updatedData
        updating = false
        
        if completion != nil { completion!() }
    }
    
    func getPagedDataFetchFailureBlock() -> AFHTTPFailureBlock {
        let failure: AFHTTPFailureBlock = {[weak self] task, error in
            if self != nil {
                self!.updating = false
            }
            defaultAFHTTPFailureBlock!(task: task, error: error)
        }
        
        return failure
    }
    
}