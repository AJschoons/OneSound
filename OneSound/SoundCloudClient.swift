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
typealias DataTaskCompletionHandlerForNoError = ((NSData!, NSURLResponse!) -> ()) // response, responseObject

class SCClient {
    
    lazy var urlSessionManager: AFURLSessionManager = {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        return AFURLSessionManager(sessionConfiguration: config)
    }()
    
    lazy var httpSessionManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager(baseURL: NSURL(string: SCBaseURL))
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.responseSerializer = AFJSONResponseSerializer()
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
    func downloadSoundCloudSongData(songID: Int, completion: DataTaskCompletionHandlerForNoError) {
        let songURL = NSURL(string: "\(SCBaseURL)tracks/\(songID)/stream?client_id=\(SCClientID)")
        
        let dataTask = urlSessionManager.session.dataTaskWithURL(songURL,
            completionHandler: { data, response, error in
                if error {
                    println("ERROR: \(error)")
                } else {
                    completion(data, response)
                }
            })
        dataTask.resume()
    }
}

extension SCClient {
    // MARK: searching songs and getting songs by their id
}