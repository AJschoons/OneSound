//
//  API.swift
//  OneSound
//
//  Created by adam on 7/8/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation
import UIKit

// use "task, responseObject in"
typealias AFHTTPSuccessBlock = ((task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void)?
// use "task, error in"
typealias AFHTTPFailureBlock = ((task: NSURLSessionDataTask!, error: NSError!) -> Void)?
typealias repeatBlock = () -> ()

let defaultAFHTTPFailureBlock: AFHTTPFailureBlock = { task, error in
    if task {
        if error {
            let alertView = UIAlertView(title: error.localizedDescription, message: error.localizedRecoverySuggestion, delegate: nil, cancelButtonTitle: "Ok")
            alertView.show()
        }
    }
}

func errorShouldBeHandedWithRepeatedRequest(task: NSURLSessionDataTask!, error: NSError!, attemptsLeft: Int? = nil) -> Bool {
    var shouldRepeatRequest = false
    if task {
        if error {
            let code = error.code
            if code == -1001 || code == -1003 || code == -1004 || code == -1005 || code == -1009 {
                // If timed out, cannot find host, cannot connect to host, connection lost, not connected to internet
                shouldRepeatRequest = true
                println("SHOULD BE TRYING TO REPEAT ATTEMPT")
            }
        }
    }
    
    if attemptsLeft {
        return (shouldRepeatRequest && (attemptsLeft > 0))
    } else {
        return shouldRepeatRequest
    }
}

let defaultAFHTTPFailureBlockForSigningIn: AFHTTPFailureBlock = { task, error in
    // Let the app know to stop showing the splash screen
    NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoginFlowNotification, object: nil)
    defaultAFHTTPFailureBlock!(task: task, error: error)
}

let defaultEA = 2

let baseURLString = "http://sparty.onesoundapp.com/"

class OSAPI: AFHTTPSessionManager {
    
    class var sharedClient: OSAPI {
        struct Static {
            static let api: OSAPI = {
                NSURLSessionConfiguration()
                let initAPI = OSAPI(baseURL: NSURL(string: baseURLString))
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
    
    // Get a user's generic information that is available to everyone
    func GETUser(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Create a URL string from the base URL string, then user/:uid
        let urlString = "\(baseURLString)user/\(uid)"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandedWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETUser(uid, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }

        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    // Get a list of users the current user is following
    func GETUserFollowing(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Create a URL string from the base URL string, then user/following/:uid
        let urlString = "\(baseURLString)user/\(uid)/following"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandedWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETUserFollowing(uid, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    // Get a list of users the current user has following them
    func GETUserFollowers(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Create a URL string from the base URL string, then user/following/:uid
        let urlString = "\(baseURLString)user/\(uid)/followers"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandedWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETUserFollowers(uid, success: success, failure: failure, extraAttempts: (extraAttempts
                     - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    // Update the user's info with a new name and color
    func PUTUser(uid: Int, apiToken: String, newName: String?, newColor: String?, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Only make put request if given value to change
        if newName || newColor {
            // Create a URL string from the base URL string, then user/:uid
            let urlString = "\(baseURLString)user/\(uid)"
            
            // Create parameters to pass
            var params = Dictionary<String, AnyObject>()
            params.updateValue(apiToken, forKey: "api_token")
            if newName { params.updateValue(newName!, forKey: "name") }
            if newColor { params.updateValue(newColor!, forKey: "color") }
            
            let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
                if errorShouldBeHandedWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                    self.PUTUser(uid, apiToken: apiToken, newName: newName, newColor: newColor, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
                } else {
                    failure!(task: task, error: error)
                }
            }
            
            PUT(urlString, parameters: params, success: success, failure: failure)
        }
    }
    
    // Upgrade guest user to a full user. Provider can only be facebook, for now
    func POSTUserProvider(userName: String, userColor: String, userID: Int, userAPIToken: String, providerUID: String, providerToken: String, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Checks if facebook id already in the database. Called before creating user so user can login to old account
        let urlString = "\(baseURLString)user/facebook"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(userName, forKey: "name")
        params.updateValue(userColor, forKey: "color")
        params.updateValue(userID, forKey: "uid")
        params.updateValue(userAPIToken, forKey: "api_token")
        params.updateValue(providerUID, forKey: "p_uid")
        params.updateValue(providerToken, forKey: "token")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandedWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.POSTUserProvider(userName, userColor: userColor, userID: userID, userAPIToken: userAPIToken, providerUID: providerUID, providerToken: providerToken, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        POST(urlString, parameters: params, success: success, failure: failure)
    }
    
    // func POSTFollowUser
    
    // func POSTUnfollowUser
    
    // Creates a guest account
    func GETGuestUser(#success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Create a URL string from the base URL string, then guest
        let urlString = "\(baseURLString)guest"
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    // Login full user from Facebook. Checks if Facebook ID is already in database / active
    // If active, returns api_token and uid of user. If not, user must be setup
    func GETUserLoginProvider(userID: Int, userAPIToken: String, providerUID: String, providerToken: String, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Checks if facebook id already in the database. Called before creating user so user can login to old account
        let urlString = "\(baseURLString)login/facebook"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(userID, forKey: "uid")
        params.updateValue(userAPIToken, forKey: "api_token")
        params.updateValue(providerUID, forKey: "p_uid")
        params.updateValue(providerToken, forKey: "token")
        
        GET(urlString, parameters: params, success: success, failure: failure)
    }
    
    // Login guest user. Returns new token
    func GetUserLoginGuest(userID: Int, userAPIToken: String, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Refreshes the guest user's API Token
        let urlString = "\(baseURLString)login/guest"
        
        // Create paramaters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(userID, forKey: "uid")
        params.updateValue(userAPIToken, forKey: "api_token")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandedWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GetUserLoginGuest(userID, userAPIToken: userAPIToken, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: params, success: success, failure: failureWithExtraAttempt)
    }
}

extension OSAPI {
    // TODO: Error handling
    // https://github.com/AFNetworking/AFNetworking/issues/596 << see danielr's comment
    // http://stackoverflow.com/questions/2069039/error-handling-with-nsurlconnection-sendsynchronousrequest
    // http://stackoverflow.com/questions/12893837/afnetworking-handle-error-globally-and-repeat-request
    // https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html
    
    // http://stackoverflow.com/questions/16705934/keep-track-of-how-many-times-a-recursive-function-has-been-called-in-c
    // http://stackoverflow.com/questions/22333020/afnetworking-2-0-unexpected-nsurlerrordomain-error-1012?rq=1
    
}