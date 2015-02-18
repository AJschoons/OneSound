//
//  FacebookManager.swift
//  OneSound
//
//  Created by adam on 2/3/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation

let facebookInitialSessionPermissions = ["public_profile"] // The permissions accessed without explicitly asking user

// Handles the login flow with Facebook and the OneSound API
class LoginFlowManager {
    
    class var sharedManager: LoginFlowManager {
        struct Static {
            static let loginFlowManager = LoginFlowManager()
        }
        return Static.loginFlowManager
    }
    
    // Use on app launch
    func startLoginFlow() {
        
        // Get saved info from the keychain
        let userID: Int? = SSKeychain.passwordForService(service, account: userIDKeychainKey) != nil ? SSKeychain.passwordForService(service, account: userIDKeychainKey).toInt() : nil
        let userAccessToken: String? = SSKeychain.passwordForService(service, account: userAccessTokenKeychainKey)
        let userGuestBool: String? = SSKeychain.passwordForService(service, account: userGuestBoolKeychainKey)
        
        // Relevant tests from saved info
        var userFoundInKeychain = (userID != nil && userAccessToken != nil && userGuestBool != nil)
        var userIsGuest = true
        if userFoundInKeychain && userGuestBool == userGuestBoolKeychainValueIsNotGuest { userIsGuest = false }
        
        // If a user is found, sign them in
        if userFoundInKeychain {
            
            // If the user was a non-guest, sign them in with Facebook
            if !userIsGuest {
                
                // If there's a cached token, just open the session silently, without showing the user the login UI
                if FBSession.activeSession().state == FBSessionState.CreatedTokenLoaded {

                    FBSession.openActiveSessionWithReadPermissions(facebookInitialSessionPermissions, allowLoginUI: false, completionHandler: {[unowned self] session, state, error in
                            // Handles what to do next based on the state
                            self.facebookSessionStateChanged(session, state: state, error: error)
                        }
                    )
                
                // No cached token, so sign them in and show the login UI
                } else {

                    FBSession.openActiveSessionWithReadPermissions(facebookInitialSessionPermissions, allowLoginUI: true, completionHandler: {[unowned self] session, state, error in
                            // Handles what to do next based on the state
                            self.facebookSessionStateChanged(session, state: state, error: error)
                        }
                    )
                }
                
            // User was a guest, so make sure all tokens cleared and then sign in guest account
            } else {
                FBSession.activeSession().closeAndClearTokenInformation()
                UserManager.sharedUser.signIntoGuestAccount(userID!, userAccessToken: userAccessToken!)
            }
            
        // User wasn't found in keychain, so make sure all tokens cleared and then setup guest account
        } else {
            FBSession.activeSession().closeAndClearTokenInformation()
            UserManager.sharedUser.setupGuestAccount()
        }
        
    }
    
    // Handler for session state changes
    // This method will be called EACH time the session state changes,
    // also for intermediate states and NOT just when the session open
    func facebookSessionStateChanged(session: FBSession, state: FBSessionState, error: NSError!) {
        
        // Get saved info from the keychain
        let userID: Int? = SSKeychain.passwordForService(service, account: userIDKeychainKey) != nil ? SSKeychain.passwordForService(service, account: userIDKeychainKey).toInt() : nil
        let userAccessToken: String? = SSKeychain.passwordForService(service, account: userAccessTokenKeychainKey)
        let userGuestBool: String? = SSKeychain.passwordForService(service, account: userGuestBoolKeychainKey)
        
        // Relevant tests from saved info
        var userFoundInKeychain = (userID != nil && userAccessToken != nil && userGuestBool != nil)
        var userIsGuest = true
        if userFoundInKeychain && userGuestBool == userGuestBoolKeychainValueIsNotGuest { userIsGuest = false }
        // Note this extra check to see if user is guest isn't done in startLoginFlow()
        userIsGuest = userIsGuest || (UserManager.sharedUser.guest != nil && UserManager.sharedUser.guest == false)
        var keychainUserAlreadySignedIn = userFoundInKeychain && UserManager.sharedUser.setup && userID == UserManager.sharedUser.id
        
        
        
        
        // Handle the session state change...
        
        // If the session was opened successfully
        if error == nil && state == .Open {
            handleFacebookOpenSession(session, userID: userID, userAccessToken: userAccessToken, userFoundInKeychain: userFoundInKeychain)
            return
        }
        
        // If the session is closed
        if state == .Closed || state == .ClosedLoginFailed {
            handleFacebookClosedSession(session, userID: userID, userAccessToken: userAccessToken, userFoundInKeychain: userFoundInKeychain, userIsGuest: userIsGuest, keychainUserAlreadySignedIn: keychainUserAlreadySignedIn)
        }
        
        // Handle errors
        if error != nil {
            // Make sure splash screen would get closed at this point in the Login Flow
            NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoginFlowNotification, object: nil)
            
            handleFacebookErrors(error!) // Always calls .closeAndClearTokenInformation()
        }
    }
    
    private func handleFacebookOpenSession(session: FBSession, userID: Int?, userAccessToken: String?, userFoundInKeychain: Bool) {
        
        let accessTokenData = session.accessTokenData
        let userFBAccessToken = accessTokenData.accessToken
        
        // If a user is found, sign them in
        if userFoundInKeychain {
                
            // If there's an available access token, sign both guests and non-guests in with it
            // (guests "signing into a full account" happens when setting up a new account... I think)
            if FBSession.activeSession().isOpen && userFBAccessToken != nil {
                UserManager.sharedUser.signIntoFullAccount(userID!, userAccessToken: userAccessToken!, fbAuthToken: userFBAccessToken)
                
            // No available access token, so close and reopen session (not sure when this would ever happen)
            } else {
                FBSession.activeSession().closeAndClearTokenInformation()
                FBSession.openActiveSessionWithReadPermissions(facebookInitialSessionPermissions, allowLoginUI: true, completionHandler: {[unowned self] session, state, error in
                        self.facebookSessionStateChanged(session, state: state, error: error)
                    }
                )
            }
            
        // User wasn't found in keychain, so make sure all tokens cleared and then setup guest account
        } else {
            FBSession.activeSession().closeAndClearTokenInformation()
            UserManager.sharedUser.setupGuestAccount()
        }
    }
    
    private func handleFacebookClosedSession(session: FBSession, userID: Int?, userAccessToken: String?, userFoundInKeychain: Bool, userIsGuest: Bool, keychainUserAlreadySignedIn: Bool) {
        
        // Make sure the session is closed and cleared
        FBSession.activeSession().closeAndClearTokenInformation()
        
        // If a guest or full user is found in the keychain
        if userFoundInKeychain {
            
            // If session gets closed on a non-guest, delete all info and setup a new guest account
            if !userIsGuest {
                
                UserManager.sharedUser.deleteAllSavedUserInformation(completion: nil)
                UserManager.sharedUser.setupGuestAccount()
                
                // NEVER EVER USE THIS CODE BELOW
                // Somehow this snippet below caused itself to be called when changing state to host streamable
                /*
                UserManager.sharedUser.deleteAllSavedUserInformation(completion: {
                    UserManager.sharedUser.setupGuestAccount()
                })*/
                
            // User was a guest
            } else {
                
                // Guest isn't signed in, so sign them in
                if !keychainUserAlreadySignedIn {
                    UserManager.sharedUser.signIntoGuestAccount(userID!, userAccessToken: userAccessToken!)
                    
                // Guest user is already signed in
                } else {
                    // Nothing else needs to be done if they're already signed in
                    let somethingToSetABreakpointOn = ""
                }
            }
            
        // No guest or full user found in the keychain, so setup a guest account
        } else {
            UserManager.sharedUser.setupGuestAccount()
        }
        
    }
    
    private func handleFacebookErrors(error: NSError) {
        println("Facebook error")
        // If the error requires people using an app to make an action outside of the app in order to recover
        if FBErrorUtility.shouldNotifyUserForError(error) {
            let alertTitle = "Something went wrong"
            let alertMessage = FBErrorUtility.userMessageForError(error)
            let alert = UIAlertView(title: alertTitle, message: alertMessage, delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
            alert.tag = AlertTag.FacebookNotifyUserForError.rawValue
            AlertManager.sharedManager.showAlert(alert)
            
        // Error doesn't need to be handled outside of the app
        } else {
            
            // If the user cancelled login, do nothing
            if FBErrorUtility.errorCategoryForError(error) == .UserCancelled {
                println("User cancelled login")
                
            // Handle session closures that happen outside of the app
            } else if FBErrorUtility.errorCategoryForError(error) == .AuthenticationReopenSession {
                let alertTitle = "Facebook Session Error"
                let alertMessage = "Your current session is no longer valid. Please sign in with Facebook again, or have a temporary guest account setup instead"
                let alert = UIAlertView(title: alertTitle, message: alertMessage, delegate: nil, cancelButtonTitle: "Setup Guest", otherButtonTitles: "Sign In")
                alert.tag = AlertTag.FacebookSessionError.rawValue
                AlertManager.sharedManager.showAlert(alert)
                
            // Handle all other errors with a generic error message (total pain to get it)
            } else {
                if let userInfo = error.userInfo {
                    if let rkey = userInfo["com.facebook.sdk:ParsedJSONResponseKey"] as? [NSObject : AnyObject] {
                        if let body = rkey["body"] as? [NSObject : AnyObject] {
                            if let error = body["error"] as? [NSObject : AnyObject] {
                                if let errorMessage = error["message"] as? String {
                                    let alertTitle = "Something went wrong"
                                    let alertMessage = "Facebook problem. Please try again. If the problem persists contact us and mention this error code: \(errorMessage)"
                                    let alert = UIAlertView(title: alertTitle, message: alertMessage, delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                                    AlertManager.sharedManager.showAlert(alert)
                                }
                            }
                        }
                        
                    }
                }
            }
        }
        
        // Error, so clear this token
        FBSession.activeSession().closeAndClearTokenInformation()
    }
    
    // Handle needing to reauthenticate a session
    func onFacebookSessionErrorAlertWithButtonIndex(buttonIndex: Int) {
        // "Setup Guest": should setup guest account
        if buttonIndex == 0 {
            FBSession.activeSession().closeAndClearTokenInformation()
            UserManager.sharedUser.setupGuestAccount()
            
        // "Sign In": should sign back in
        } else if buttonIndex == 1 {
            FBSession.openActiveSessionWithReadPermissions(facebookInitialSessionPermissions, allowLoginUI: false, completionHandler: {[unowned self] session, state, error in
                // Handles what to do next based on the state
                self.facebookSessionStateChanged(session, state: state, error: error)
                }
            )
        }
    }
}
