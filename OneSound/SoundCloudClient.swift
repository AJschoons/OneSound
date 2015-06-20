//
//  SoundCloudClient.swift
//  OneSound
//
//  Created by adam on 7/28/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation

let SCClientID = "d9b5ddf849438ccddca1256ba5c03067"
let SCBaseURL = "https://api.soundcloud.com/"
typealias DataTaskCompletionHandlerForNoError = ((NSData!, NSURLResponse!) -> ()) // data, response
typealias DataTaskCompletionHandler = ((NSData!, NSURLResponse!, NSError!) -> ()) // data, response, error

class SCClient {
    
    lazy var urlSessionManager: AFURLSessionManager = {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        return AFURLSessionManager(sessionConfiguration: config)
    }()
    
    lazy var httpSessionManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager(baseURL: NSURL(string: SCBaseURL))
        manager.requestSerializer = AFJSONRequestSerializer() as AFJSONRequestSerializer
        manager.responseSerializer = AFJSONResponseSerializer() as AFJSONResponseSerializer
        return manager
    }()
    
    class var sharedClient: SCClient {
    struct Static {
        static let client = SCClient()
        }
        return Static.client
    }
}

extension SCClient {
    // MARK: downloading songs
    func downloadSoundCloudSongData(songID: String, completion: DataTaskCompletionHandler) {
        let songURL = NSURL(string: getSongURLString(songID))
        
        let dataTask = urlSessionManager.session.dataTaskWithURL(songURL!, completionHandler: completion)
        dataTask.resume()
    }
    
    func getSongURLString(songID: String) -> String {
        let songURLString = "\(SCBaseURL)tracks/\(songID)/stream?client_id=\(SCClientID)"
        return songURLString
    }
}

extension SCClient {
    // MARK: searching songs and getting songs by their id
    
    func searchSoundCloudForSongWithString(str: String, extraAttempts: Int = defaultEA, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Create a URL string from the base URL string, then user/:uid
        let urlString = "\(SCBaseURL)tracks.json"
        
        var params = Dictionary<String, AnyObject>()
        params.updateValue(SCClientID, forKey: "consumer_key")
        params.updateValue(str, forKey: "q")
        params.updateValue("streamable", forKey: "filter")
        params.updateValue("hotness", forKey: "order")
        params.updateValue(SongDurationMaxInSeconds * 1000, forKey: "duration-to") // 10 minute max
        params.updateValue(25, forKey: "limit") // Just get 25 results (default is 50)
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.searchSoundCloudForSongWithString(str, extraAttempts: (extraAttempts - 1), success: success, failure: failure)
            } else {
                failure!(task: task, error: error)
            }
        }
        
        httpSessionManager.GET(urlString, parameters: params, success: success, failure: failure)
    }
    
    // (Only used when initially testing audio player for party)
    
    func getSoundCloudSongByID(songID: Int, extraAttempts: Int = defaultEA, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        // Create a URL string from the base URL string, then user/:uid
        let urlString = "\(SCBaseURL)tracks/\(songID).json"
        
        var params = Dictionary<String, AnyObject>()
        params.updateValue(SCClientID, forKey: "consumer_key")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(task, error, attemptsLeft: extraAttempts) {
                self.getSoundCloudSongByID(songID, extraAttempts: (extraAttempts - 1), success: success, failure: failure)
            } else {
                failure!(task: task, error: error)
            }
        }
        
        httpSessionManager.GET(urlString, parameters: params, success: success, failure: failure)
    }
}