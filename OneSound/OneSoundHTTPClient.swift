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
    let alertView = UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok")
    alertView.show()
}

let defaultAFHTTPFailureBlockForServerDown: AFHTTPFailureBlock = { task, error in
    let alertView = UIAlertView(title: "Server Temporarily Down", message: "We're having some problems on our end, please try using OneSound again in a couple of minutes", delegate: nil, cancelButtonTitle: "Ok")
    alertView.show()
    println(error.localizedDescription)
}

let baseURLString = "http://sparty.onesoundapp.com/"

class OSAPI: AFHTTPSessionManager {
    
    class var sharedClient: OSAPI {
        struct Static {
            static let api: OSAPI = {
                let initAPI = OSAPI()
                initAPI.requestSerializer = AFJSONRequestSerializer()
                initAPI.responseSerializer = AFJSONResponseSerializer()
                return initAPI
            }()
        }
        return Static.api
    }
}

extension OSAPI {
    // MARK: User-related API
    
    func GETUser(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Create a URL string from the base URL string, then user/:uid
        let urlString = "\(baseURLString)user/\(uid)"

        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    func GETUserFollowing(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Create a URL string from the base URL string, then user/following/:uid
        let urlString = "\(baseURLString)user/\(uid)/following"
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }

    func GETUserFollowers(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Create a URL string from the base URL string, then user/following/:uid
        let urlString = "\(baseURLString)user/\(uid)/followers"
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    func PUTUser(uid: Int, apiToken: String, newName: String?, newColor: String?, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Only make put request if given value to change
        if newName || newColor {
            // Create a URL string from the base URL string, then user/:uid
            let urlString = "\(baseURLString)user/\(uid)"
            
            // Create parameters to pass
            var params = Dictionary<String, AnyObject>()
            params.updateValue(apiToken, forKey: "api_token")
            if newName { params.updateValue(newName!, forKey: "name") }
            if newColor { params.updateValue(newColor!, forKey: "color") }
            
            PUT(urlString, parameters: params, success: success, failure: failure)
        }
    }
    
    // func POSTUserProvider
    
    // func POSTFollowUser
    
    // func POSTUnfollowUser
    
    func GETGuestUser(#success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Create a URL string from the base URL string, then guest
        let urlString = "\(baseURLString)guest"
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    func GETUserLoginProvider(providerUID: String, providerToken: String, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Checks if facebook id already in the database. Called before creating user so user can login to old account
        let urlString = "/login/facebook"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(providerUID, forKey: "p_uid")
        params.updateValue(providerToken, forKey: "token")
        
        GET(urlString, parameters: params, success: success, failure: failure)
    }
}
