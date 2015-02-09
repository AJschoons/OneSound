 //
//  AlertManager.swift
//  OneSound
//
//  Created by adam on 2/4/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation

// Manages alerts for singletons
class AlertManager: NSObject {
    
    private var shouldShowAlerts = false
    private var showingAlert: UIAlertView?
    private var alertQueue = [UIAlertView]()
    
    private var isShowingAlert: Bool {
        return showingAlert != nil
    }
    
    class var sharedManager: AlertManager {
        struct Static {
            static let alertManager = AlertManager()
        }
        return Static.alertManager
    }
    
    // This is the only function that should be used to show / add an alert to the queue
    func showAlert(alert: UIAlertView) {
        
        alert.delegate = self
        
        // If an alert is already showing, or new alerts shouldn't be showing, then add this alert to the queue
        if isShowingAlert || !shouldShowAlerts {
            addAlertToQueue(alert: alert)
            
        // This alert should be shown now
        } else {
            if let rvc = getRootViewController() {
                showingAlert = alert
                alert.show()
            }
        }
    }
    
    // Only adds alerts that aren't already in the queue
    private func addAlertToQueue(alert alertToAdd: UIAlertView) {
        
        // Don't add alert if it's already queued or showing
        if isShowingAlert && alertsAreEqual(alertAlreadyManaged: showingAlert!, alertToCheck: alertToAdd) {
            return
        }
        
        for alert in alertQueue {
            if alertsAreEqual(alertAlreadyManaged: alert, alertToCheck: alertToAdd) {
                return
            }
        }
        
        // Alert not already showing or in queue, so add it to the queue
        alertQueue.append(alertToAdd)
    }
    
    private func alertDidDismiss() {
        showingAlert = nil
        showNextAlert()
    }
    
    private func showNextAlert() {
        // Make sure there's an alert to show
        if alertQueue.count == 0 { return }

        // Check the queue for the next alert
        if let rvc = getRootViewController() {
            let nextAlert = alertQueue.removeAtIndex(0)
            
            showingAlert = nextAlert
            nextAlert.show()
        }
    }
    
    // True if the alertToCheck (alert that either will be shown or added to queue) tag isn't zero and has same tag
    private func alertsAreEqual(# alertAlreadyManaged: UIAlertView, alertToCheck: UIAlertView) -> Bool {
        return alertAlreadyManaged.tag == alertToCheck.tag
    }
    
    func onLoggingInSpashViewControllerDidDisappear() {
        shouldShowAlerts = true
        // Give app some time to get ready, otherwise won't show the alert...?
        delayOnMainQueueFor(numberOfSeconds: 0.1, action: {
            self.showNextAlert()
        })
    }
    
}
 
extension AlertManager: UIAlertViewDelegate {
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        
        // Do anything else for specific alerts here...
        
        if alertView.tag == AlertTag.FacebookSessionError.rawValue {
            LoginFlowManager.sharedManager.onFacebookSessionErrorAlertWithButtonIndex(buttonIndex)
        }
        
        // Make sure this gets called last; get the next alert to show after dismiss and button press handled
        alertDidDismiss()
    }
}