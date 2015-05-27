//
//  LocationManager.swift
//  OneSound
//
//  Created by adam on 5/22/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation

typealias LocationSuccessBlock = (location: CLLocation, accuracy: INTULocationAccuracy) -> Void
typealias LocationFailureBlock = (errorDesciption: String) -> Void

// Manages location for user
class LocationManager: NSObject {
    
    static func getLocationForPartySearch(#success: LocationSuccessBlock, failure: LocationFailureBlock) {
        let locMgr = INTULocationManager.sharedInstance()
        
        locMgr.requestLocationWithDesiredAccuracy(INTULocationAccuracy.House, timeout: 10.0, delayUntilAuthorized: true, block: {currentLocation, accuracy, status in
            
            // Got location within Block distance of ~100 meters
            if status == .Success || (currentLocation != nil && accuracy == .Block) {
                success(location: currentLocation, accuracy: accuracy)
            } else if status == .TimedOut {
                failure(errorDesciption: "Could not determine location within 300ft. Please try again in better conditions")
            } else {
                failure(errorDesciption: self.getINTUStatusErrorMessageFromStatus(status))
            }
        })
    }
    
    private static func getINTUStatusErrorMessageFromStatus(status: INTULocationStatus) -> String {
        switch status {
        case .ServicesNotDetermined:
            return "Must respond to the dialog to grant OneSound permission to access location services"
        case .ServicesDenied:
            return "OneSound has been explicitly deined permission to access location services. Please go to Settings>OneSound>Location to allow this feature."
        case .ServicesRestricted:
            return "Location services have been turned off device-wide (for all apps) from the system Settings app. Location services are required for this feature"
        case .ServicesDisabled:
            return "An error occurred while using the system location services. Please try again"
        default:
            return ""
        }
    }
    
}
