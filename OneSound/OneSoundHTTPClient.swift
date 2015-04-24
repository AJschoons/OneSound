//
//  API.swift
//  OneSound
//
//  Created by adam on 7/8/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation
import UIKit

let accessTokenHeaderKey = "ACCESS_TOKEN"

// use "task, responseObject in"
typealias AFHTTPSuccessBlock = ((task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void)?
// use "task, error in"
typealias AFHTTPFailureBlock = ((task: NSURLSessionDataTask!, error: NSError!) -> Void)?
typealias repeatBlock = () -> ()

let defaultAFHTTPFailureBlock: AFHTTPFailureBlock = { task, error in
    if task != nil {
        var haveHTTPCodeErrorMessage = false
        
        if let response = task.response as? NSHTTPURLResponse {
            let code = response.statusCode
            if code == 400 || code == 401 || code == 404 || code == 500 || code == 503 {
                haveHTTPCodeErrorMessage = true
                var alert: UIAlertView
                
                switch code {
                case 400:
                    alert = UIAlertView(title: "Bad Request", message: "Sent invalided JSON request to the server", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                    alert.tag = AlertTag.HTTP400.rawValue
                case 401:
                    alert = UIAlertView(title: "Unauthorized", message: "Authentication is required and has failed or has not yet been provided", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                    alert.tag = AlertTag.HTTP401.rawValue
                case 404:
                    alert = UIAlertView(title: "Not Found", message: "The requested resource could not be found but may be available again in the future", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                    alert.tag = AlertTag.HTTP404.rawValue
                case 500:
                    alert = UIAlertView(title: "Internal Server Error", message: "Sorry, we're having problems on our end. Please try again", delegate: OSAPI.sharedClient, cancelButtonTitle: defaultAlertCancelButtonText)
                    alert.tag = AlertTag.HTTP500.rawValue
                case 503:
                    alert = UIAlertView(title: "Service Unavailable", message: "Either \(appName), SoundCloud, or one of our other providers is currently unavailble. Please try again", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                    alert.tag = AlertTag.HTTP503.rawValue
                default:
                    alert = UIAlertView(title: "Down For Maintenance", message: "\(appName) is currently down for maintenance, we will have it back up shortly. Please try again", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                    alert.tag = AlertTag.HTTPDefault.rawValue
                }
                AlertManager.sharedManager.showAlert(alert)
            } 
        }
        
        if error != nil && !haveHTTPCodeErrorMessage {
            var alert: UIAlertView
            let code = error.code
            println("ERROR: has the following code... \(code)")
            println(error.localizedDescription)
            switch code {
            case -1001:
                alert = UIAlertView(title: "Connection Timed Out", message: "Couldn't connect to the server in time, please try again with a better internet connection", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.tag = AlertTag.URLError1001.rawValue
            case -1003:
              alert = UIAlertView(title: "Cannot Find Host", message: "Couldn't find host to connect to, please try again with a better internet connection", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.tag = AlertTag.URLError1003.rawValue
            case -1004:
                alert = UIAlertView(title: "Cannot Connect To Host", message: "Couldn't find host to connect to, please try again with a better internet connection", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.tag = AlertTag.URLError1004.rawValue
            case -1005:
                alert = UIAlertView(title: "Network Connection Lost", message: "Internet connection was lost, please try again with a better connection", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.tag = AlertTag.URLError1005.rawValue
            case -1009:
                alert = UIAlertView(title: "Not Connected To Internet", message: "Internet connection was lost, please try again after reconnecting", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.tag = AlertTag.URLError1009.rawValue
            case -1011:
                // Should be getting this when the server sends a 500 response code
                alert = UIAlertView(title: "Down For Maintenance", message: "OneSound is currently down for maintenance, we will have it back up shortly. Please try again", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.tag = AlertTag.URLError1011.rawValue
            default:
                alert = UIAlertView(title: error.localizedDescription, message: error.localizedRecoverySuggestion, delegate: OSAPI.sharedClient, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.tag = AlertTag.URLErrorDefault.rawValue
            }
            AlertManager.sharedManager.showAlert(alert)
        }
    }
}

func errorShouldBeHandledWithRepeatedRequest(task: NSURLSessionDataTask!, error: NSError!, attemptsLeft: Int? = nil) -> Bool {
    var shouldRepeatRequest = false
    if task != nil {
        if error != nil {
            let code = error.code
            if code == -1001 || code == -1003 || code == -1004 || code == -1005 || code == -1009 || code == -1011 {
                // If timed out, cannot find host, cannot connect to host, connection lost, not connected to internet, server 500 code equivalent
                shouldRepeatRequest = true
                println("SHOULD BE TRYING TO REPEAT ATTEMPT")
            }
        }
    }
    
    if attemptsLeft != nil {
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

let baseURLString = "https://sparty.onesoundapp.com/"

class OSAPI: AFHTTPSessionManager {
    
    class var sharedClient: OSAPI {
        struct Static {
            static let api: OSAPI = {
                let config = NSURLSessionConfiguration.defaultSessionConfiguration()
                config.HTTPAdditionalHeaders = ["CLIENT_ID" : "1", "CLIENT_SECRET" : "d7aa3fcb7141e876cea6121b600d1d8854ea74d7"]
                
                let initAPI = OSAPI(baseURL: NSURL(string: baseURLString), sessionConfiguration: config)
                
                initAPI.requestSerializer = AFJSONRequestSerializer() as AFJSONRequestSerializer
                initAPI.responseSerializer = AFJSONResponseSerializer() as AFJSONResponseSerializer
                
                // http://stackoverflow.com/questions/12967220/i-want-to-allow-invalid-ssl-certificates-with-afnetworking (answer from titaniumdecoy)
                var securityPolicy = AFSecurityPolicy(pinningMode: AFSSLPinningMode.None)
                securityPolicy.allowInvalidCertificates = true
                initAPI.securityPolicy = securityPolicy
                
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
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
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
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    // Get a list of users the current user has following them
    func GETUserFollowers(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Create a URL string from the base URL string, then user/following/:uid
        let urlString = "\(baseURLString)user/\(uid)/followers"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETUserFollowers(uid, success: success, failure: failure, extraAttempts: (extraAttempts
                     - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    // Update the user's info with a new name and color
    func PUTUser(uid: Int, newName: String?, newColor: String?, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Only make put request if given value to change
        if newName != nil || newColor != nil {
            // Create a URL string from the base URL string, then user/:uid
            let urlString = "\(baseURLString)user/\(uid)"
            
            // Create parameters to pass
            var params = Dictionary<String, AnyObject>()
            if newName != nil { params.updateValue(newName!, forKey: "name") }
            if newColor != nil { params.updateValue(newColor!, forKey: "color") }
            
            let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
                if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                    self.PUTUser(uid, newName: newName, newColor: newColor, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
                } else {
                    failure!(task: task, error: error)
                }
            }
            
            PUT(urlString, parameters: params, success: success, failure: failure)
        }
    }
    
    // Upgrade guest user to a full user. Provider can only be facebook, for now
    func POSTUserProvider(userName: String, userColor: String, providerToken: String, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Checks if facebook id already in the database. Called before creating user so user can login to old account
        let urlString = "\(baseURLString)user/facebook"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(userName, forKey: "name")
        params.updateValue(userColor, forKey: "color")
        params.updateValue(providerToken, forKey: "token")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            var shouldConsiderRepeatedRequest = true
            
            // Don't try extra attempts for a 401; will be handled
            if let response = task.response as? NSHTTPURLResponse {
                if response.statusCode == 401 {
                    shouldConsiderRepeatedRequest = false
                    failure!(task: task, error: error)
                }
            }
            
            if shouldConsiderRepeatedRequest {
                if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                    self.POSTUserProvider(userName, userColor: userColor, providerToken: providerToken, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
                } else {
                    failure!(task: task, error: error)
                }
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
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETGuestUser(success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    // Login full user from Facebook. Checks if Facebook ID is already in database / active
    // If active, returns access_token of user. If not, user must be setup
    func GETUserLoginProvider(providerToken: String, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Checks if facebook id already in the database. Called before creating user so user can login to old account
        let urlString = "\(baseURLString)login/facebook"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(providerToken, forKey: "token")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            var shouldConsiderRepeatedRequest = true
            
            // Don't try extra attempts for a 401; will be handled
            if let response = task.response as? NSHTTPURLResponse {
                if response.statusCode == 401 {
                    shouldConsiderRepeatedRequest = false
                    failure!(task: task, error: error)
                }
            }
            
            if shouldConsiderRepeatedRequest {
                if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                    self.GETUserLoginProvider(providerToken, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
                } else {
                    failure!(task: task, error: error)
                }
            }
        }
        
        GET(urlString, parameters: params, success: success, failure: failure)
    }
    
    // Login guest user. Returns new token
    func GETUserLoginGuest(# success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Refreshes the guest user's API Token
        let urlString = "\(baseURLString)login/guest"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETUserLoginGuest(success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: nil, success: success, failure: failureWithExtraAttempt)
    }
    
    // Delete a user's party (leave it)
    func DELETEUserParty(uid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        
        let urlString = "\(baseURLString)user/\(uid)/party"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.DELETEUserParty(uid, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        DELETE(urlString, parameters: nil, success: success, failure: failureWithExtraAttempt)
    }
    
    // Checks to see if user's input name is valid (not taken already, etc.)
    func GETUserNameValidate(name: String, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        // Refreshes the guest user's API Token
        let urlString = "\(baseURLString)user/name/validate"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(name, forKey: "name")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETUserNameValidate(name, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: params, success: success, failure: failureWithExtraAttempt)
    }
}

extension OSAPI {
    // MARK: Party-related API
    
    // Gets the user's current party info
    func GETPartyCurrent(#success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        
        let urlString = "\(baseURLString)party/current"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            var shouldConsiderRepeatedRequest = true
            
            // Don't try extra attempts for a 404; will be handled
            if let response = task.response as? NSHTTPURLResponse {
                if response.statusCode == 404 {
                    shouldConsiderRepeatedRequest = false
                    failure!(task: task, error: error)
                }
            }
            
            if shouldConsiderRepeatedRequest {
                if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                    self.GETPartyCurrent(success: success, failure: failure, extraAttempts: (extraAttempts - 1))
                } else {
                    failure!(task: task, error: error)
                }
            }
        }
        
        GET(urlString, parameters: nil, success: success, failure: failureWithExtraAttempt)
    }
    
    // Allows user to join a party
    func GETParty(pid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        
        let urlString = "\(baseURLString)party/\(pid)"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETParty(pid, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: nil, success: success, failure: failureWithExtraAttempt)
    }
    
    // Get the party's current songs in the playlist
    func GETPartyPlaylist(pid: Int, page: Int, pageSize: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        let urlString = "\(baseURLString)party/\(pid)/playlist"
        
        var params = Dictionary<String, AnyObject>()
        params.updateValue(page, forKey: "page")
        params.updateValue(pageSize, forKey: "limit") // Server is 20 by default
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETPartyPlaylist(pid, page: page, pageSize: pageSize, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: params, success: success, failure: failureWithExtraAttempt)
    }
    
    // Get the party's members
    func GETPartyMembers(pid: Int, page: Int, pageSize: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        let urlString = "\(baseURLString)party/\(pid)/members"
        
        var params = Dictionary<String, AnyObject>()
        params.updateValue(page, forKey: "page")
        params.updateValue(pageSize, forKey: "limit") // Server is 20 by default
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETPartyMembers(pid, page: page, pageSize: pageSize, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: params, success: success, failure: failureWithExtraAttempt)
    }
    
    // Create a new party
    func POSTParty(name: String, privacy: Bool, strictness: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {

        let urlString = "\(baseURLString)party"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(name, forKey: "name")
        params.updateValue(privacy, forKey: "privacy")
        params.updateValue(strictness, forKey: "strictness")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.POSTParty(name, privacy: privacy, strictness: strictness, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        POST(urlString, parameters: params, success: success, failure: failure)
    }
    
    // Update a party's info
    func PUTParty(pid: Int, name: String, privacy: Bool, strictness: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        
        let urlString = "\(baseURLString)party/\(pid)"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(name, forKey: "name")
        params.updateValue(privacy, forKey: "privacy")
        params.updateValue(strictness, forKey: "strictness")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.PUTParty(pid, name: name, privacy: privacy, strictness: strictness, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        PUT(urlString, parameters: params, success: success, failure: failure)
    }
    
    // Search for a party by name
    func GETPartySearch(searchText: String, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        let urlString = "\(baseURLString)party/search"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(searchText, forKey: "q")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETPartySearch(searchText, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: params, success: success, failure: failureWithExtraAttempt)
    }
    
    // Update the permissions for a party. Used to reclaim music streaming control for a host
    func PUTPartyPermissions(pid: Int, musicControl: Bool, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        let urlString = "\(baseURLString)party/\(pid)/permissions"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(musicControl, forKey: "music_control")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.PUTPartyPermissions(pid, musicControl: musicControl, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        PUT(urlString, parameters: params, success: success, failure: failureWithExtraAttempt)
    }
}

extension OSAPI {
    // MARK: Song-related API
    
    // Add a song to a party playlist
    func POSTSong(pid: Int, externalID: Int, source: String, title: String, artist: String, duration: Int, artworkURL: String?,success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        
        let urlString = "\(baseURLString)song"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(pid, forKey: "pid")
        params.updateValue(externalID, forKey: "external_id")
        params.updateValue(source, forKey: "source")
        params.updateValue(title, forKey: "title")
        params.updateValue(artist, forKey: "artist")
        params.updateValue(duration, forKey: "length")
        
        if artworkURL != nil {
            params.updateValue(artworkURL!, forKey: "album")
        } else {
            params.updateValue("", forKey: "album")
        }
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.POSTSong(pid, externalID: externalID, source: source, title: title, artist: artist, duration: duration, artworkURL: artworkURL, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        POST(urlString, parameters: params, success: success, failure: failure)
    }
    
    // Delete a song from the playlist. Only works if it is the user's song
    func DELETESong(sid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        let urlString = "\(baseURLString)song/\(sid)"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.DELETESong(sid, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        DELETE(urlString, parameters: nil, success: success, failure: failureWithExtraAttempt)
    }
    
    // Get the party's current song
    func GETCurrentSong(pid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        let urlString = "\(baseURLString)party/\(pid)/currentsong"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            var shouldConsiderRepeatedRequest = true
            
            // Don't try extra attempts for a 404; will be handled by noCurrentSong
            if let response = task.response as? NSHTTPURLResponse {
                if response.statusCode == 404 {
                    shouldConsiderRepeatedRequest = false
                    failure!(task: task, error: error)
                }
            }
            
            if shouldConsiderRepeatedRequest {
                if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                    self.GETCurrentSong(pid, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
                } else {
                    failure!(task: task, error: error)
                }
            }
        }
        
        GET(urlString, parameters: nil, success: success, failure: failureWithExtraAttempt)
    }
    
    func GETNextSong(pid: Int, skipped: Bool, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        
        let urlString = "party/\(pid)/nextsong"
        
        // Create parameters to pass
        var params = Dictionary<String, AnyObject>()
        params.updateValue(skipped, forKey: "skipped")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            var shouldConsiderRepeatedRequest = true
            
            // Don't try extra attempts for a 404; will be handled by noCurrentSong
            if let response = task.response as? NSHTTPURLResponse {
                if response.statusCode == 404 {
                    shouldConsiderRepeatedRequest = false
                    failure!(task: task, error: error)
                }
            }
            
            if shouldConsiderRepeatedRequest {
                if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                    self.GETNextSong(pid, skipped: skipped, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
                } else {
                    failure!(task: task, error: error)
                }
            }
        }
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }
    
    func POSTSongUpvote(sid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        
        let urlString = "song/\(sid)/upvote"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.POSTSongUpvote(sid, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        POST(urlString, parameters: nil, success: success, failure: failure)
    }
    
    func POSTSongDownvote(sid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        
        let urlString = "song/\(sid)/downvote"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.POSTSongDownvote(sid, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        POST(urlString, parameters: nil, success: success, failure: failure)
    }
    
    func DELETESongVote(sid: Int, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = defaultEA) {
        
        let urlString = "song/\(sid)/vote"

        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.DELETESongVote(sid, success: success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        DELETE(urlString, parameters: nil, success: success, failure: failure)
    }
}

extension OSAPI {
    // MARK: General-related API
    
    // Gets the version status of the iOS app, and the total # of parties in the app
    func GETPublicInfo(success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock, extraAttempts: Int = 10) {
        let urlString = "public/info"
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.GETPublicInfo(success, failure: failure, extraAttempts: (extraAttempts - 1))
            } else {
                failure!(task: task, error: error)
            }
        }
        
        GET(urlString, parameters: nil, success: success, failure: failure)
    }
}