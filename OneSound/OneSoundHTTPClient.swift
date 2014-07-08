//
//  API.swift
//  OneSound
//
//  Created by adam on 7/8/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation

// use "task, responseObject in"
typealias AFHTTPSuccessBlock = ((task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void)?
// use "task, error in"
typealias AFHTTPFailureBlock = ((task: NSURLSessionDataTask!, error: NSError!) -> Void)?

let defaultAFHTTPFailureBlock: AFHTTPFailureBlock = { task, error in
    let alertView = UIAlertView(title: "Error retrieving user", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok")
    alertView.show()
}

let baseURLString = "http://shaw.herokuapp.com/"

class OSAPI: NSObject {
    
    class var sharedAPI: OSAPI {
        struct Static {
            static let api = OSAPI()
        }
        return Static.api
    }
    
    @lazy var manager: AFHTTPSessionManager = {
        let sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: baseURLString))
        //sessionManager.responseSerializer = AFJSONResponseSerializer
        return sessionManager
    }()
}

extension OSAPI {
    // MARK: User-related API
    
    func GETUser(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Create a URL string from the base URL string, then user/:uid
        let urlString = "\(baseURLString)user/\(uid)"
        println("GETUser \(urlString)")

        manager.GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    func GETUserFollowing(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Create a URL string from the base URL string, then user/following/:uid
        let urlString = "\(baseURLString)user/following/\(uid)"
        println("GETUserFollowing \(urlString)")
        
        manager.GET(urlString, parameters: nil, success: success, failure: failure)
    }

    func GETUserFollowers(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Create a URL string from the base URL string, then user/following/:uid
        let urlString = "\(baseURLString)user/followers/\(uid)"
        println("GETUserFollowers \(urlString)")
        
        manager.GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    // func PUTUser
    
    // func POSTUserProvider
    
    // func POSTFollowUser
    
    // func POSTUnfollowUser
    
    // func GETGuestUser
    
    // func GETUserLoginProvider
}
