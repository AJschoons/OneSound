//
//  Constants.swift
//  OneSound
//
//  Created by adam on 1/29/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation

let appName = "OneSound"
let defaultAlertCancelButtonText = "Okay"

let NavigationBarHeight: CGFloat = 64
let StatusBarHeight: CGFloat = 20

let defaultCellRowHeight: CGFloat = 64

// MARK: UIAlertView tags
enum AlertTag: Int {
    
    case SigningOutGuest = 101
    case SigningOut = 102
    case LeavingPartyAsHost = 103
    
    case LostMusicControl = 200
    case NoMusicControl = 201
    
    case NoInternetConnection = 300
    
    case FacebookNotifyUserForError = 400
    case FacebookSessionError = 401
    case FacebookOtherErrors = 402
    
    case HTTP400 = 500
    case HTTP401 = 501
    case HTTP404 = 502
    case HTTP500 = 503
    case HTTP503 = 504
    case HTTPDefault = 505
    
    case URLError1001 = 600
    case URLError1003 = 601
    case URLError1004 = 602
    case URLError1005 = 603
    case URLError1009 = 604
    case URLError1011 = 605
    case URLErrorDefault = 606
    
    case UnstreamableSongSkipped = 700
}

// MARK: VersionStatus
// Used to check the version before logging in
enum VersionStatus: Int {
    case Good = 0
    case Deprecated = 1
    case Block = 2 // Don't load the app, force an update
}