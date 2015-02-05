//
//  AlertManager.swift
//  OneSound
//
//  Created by adam on 2/4/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation

class AlertManager {
    
    var showingAlert: UIAlertView?
    
    class var sharedManager: AlertManager {
        struct Static {
            static let alertManager = AlertManager()
        }
        return Static.alertManager
    }
    
    func showUIAlertView(alert: UIAlertView) {
        
    }
    
}