//
//  AppUser.swift
//  OneSound
//
//  Created by adam on 7/17/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation

let LocalUserInformationDidChangeNotification = "LocalUserInformationDidChange"
let service = "com.AdamSchoonmaker.OneSound"
let userIDKeychainKey = "userID"
let userAPITokenKeychainKey = "userAPIToken"
let userGuestBoolKeychainKey = "userGuestBool"
let userFacebookUIDKeychainKey = "userFacebookUID"
let userFacebookAuthenticationTokenKeychainKey = "userFacebookAuthenticationTokenKey"
let userNameKey = "name"
let userColorKey = "color"
let userGuestKey = "guest"
let userPhotoUIImageKey = "photo"

class LocalUser {

    var pL = true
    
    var apiToken: String!
    var facebookUID: String?
    var facebookAuthenticationToken: String?
    
    var setup = false
    
    var id: Int!
    var name: String!
    var color: String!
    var guest: Bool!
    var photoURL: String?
    var songCount: Int!
    var voteCount: Int!
    var followers: Int!
    var following: Int!
    
    var photo: UIImage?
    
    class var sharedUser: LocalUser {
    struct Static {
        static let localUser = LocalUser()
        }
        return Static.localUser
    }
    
    // Maybe added later?
    //var soundCloudUID: String?
    //var soundCloudAccessToken: String?
    //var twitterUID: String?
    //var twitterAccessToken: String?
    //var email: String?
    
    var colorToUIColor: UIColor {
    if !color {
        setRandomColor()
    }
        
    if let userColor = UserColors.fromRaw(color) {
        switch userColor {
        case .Green:
            return UIColor.green()
        case .Purple:
            return UIColor.purple()
        case .Turquoise:
            return UIColor.turquoise()
        case .Yellow:
            return UIColor.yellow()
        case .Red:
            return UIColor.red()
        case .Orange:
            return UIColor.orange()
        }
    }
    return UIColor.brownColor()
    }
    
    class func colorToUIColor(color: String) -> UIColor {
        if let userColor = UserColors.fromRaw(color) {
            switch userColor {
            case .Green:
                return UIColor.green()
            case .Purple:
                return UIColor.purple()
            case .Turquoise:
                return UIColor.turquoise()
            case .Yellow:
                return UIColor.yellow()
            case .Red:
                return UIColor.red()
            case .Orange:
                return UIColor.orange()
            }
        }
        return UIColor.brownColor()
    }
    
    func randomColor() -> UserColors {
        // Generates a random number 0-(numberOfOneSoundColors - 1)
        let randomInt = Int(arc4random()) % numberOfOneSoundColors
        println("random int for color:\(randomInt)")
        switch randomInt {
        case 0:
            return UserColors.Green
        case 1:
            return UserColors.Turquoise
        case 2:
            return UserColors.Purple
        case 3:
            return UserColors.Red
        case 4:
            return UserColors.Orange
        case 5:
            return UserColors.Yellow
        default:
            return UserColors.Turquoise
        }
    }
    
    func setRandomColor() {
        color = randomColor().toRaw()
    }
    
    func description() -> String {
        var d = "[USER] id:\(id) name:'\(name)' color:\(color) guest:\(guest) f-ers:\(followers) f-ing:\(following) songs:\(songCount) votes:\(voteCount) photo:\(photo) apiToken:\(apiToken) setup:\(setup)"
        if facebookUID {
            d += " fUID:\(facebookUID)"
        }
        if facebookAuthenticationToken {
            d += " fToken:\(facebookAuthenticationToken)"
        }
        
        return d
    }
}

extension LocalUser {
    // MARK: Login flow relgated code
    
    func signIntoGuestAccount(id: Int, apiToken: String) {
        // For use in the login flow of signing a user in
        
        printlnC(pL, pG, "Signing in with GUEST information... userID:\(id)   userAPIToken:\(apiToken)")
        
        updateLocalUserInformationAfterSignIn(userID: id, userAPIToken: apiToken,
            failure: { task, error in
                println("ERROR: Guest account no longer exists, creating new one")
                println(error.localizedDescription)
                self.setupGuestAccount()
            }
        )
    }
    
    func setupGuestAccount() {
        // For use in the login flow of signing a user in
        printlnC(pL, pG, "Setup local guest user")
        
        // Get the guest user creation info from the server
        OSAPI.sharedClient.GETGuestUser(
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                
                // Get the guest response info
                let guestAPIToken = responseJSON["api_token"].string
                let guestUID = responseJSON["uid"].integer
                
                printlnC(self.pL, pG, "Signing in with GUEST information... userID:\(guestUID)   userAPIToken:\(guestAPIToken)")
                
                self.updateLocalUserInformationAfterSignIn(userID: guestUID!, userAPIToken: guestAPIToken!)
            },
            failure: defaultAFHTTPFailureBlockForServerDown
        )
    }
    
    func signIntoFullAccount(userID: Int, userAPIToken: String, fbUID: String, fbAuthToken: String) {
        
        OSAPI.sharedClient.GETUserLoginProvider(userID, userAPIToken: userAPIToken, providerUID: fbUID, providerToken: fbAuthToken,
            success: { data, responseObject in
                println("Signing in with FULL ACCOUNT information... userID:\(userID)   userAPIToken:\(userAPIToken)")
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let activeAccount = responseJSON["active"].bool
                if activeAccount == false {
                    // Haven't seen that Facebook account before
                    println("Account is inactive; create account")
                    
                    let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
                    let loginViewController = loginStoryboard.instantiateViewControllerWithIdentifier("LoginViewController") as LoginViewController
                    let navC = UINavigationController(rootViewController: loginViewController)
                    
                    let delegate = UIApplication.sharedApplication().delegate as AppDelegate
                    let fvc = delegate.revealViewController!.frontViewController
                    fvc.presentViewController(navC, animated: true,
                        completion: {
                            loginViewController.userID = userID
                            loginViewController.userAPIToken = userAPIToken
                            loginViewController.userFacebookUID = fbUID
                            loginViewController.userFacebookToken = fbAuthToken
                        }
                    )
                } else {
                    // Facebook account HAS been seen before
                    println("Account is active; update information and sign in")
                    
                    let userAPIToken = responseJSON["api_token"].string
                    let userID = responseJSON["uid"].integer
                    
                    self.updateLocalUserInformationAfterSignIn(userID: userID!, userAPIToken: userAPIToken!)
                }
            }, failure: defaultAFHTTPFailureBlockForServerDown
        )
    }
    
    func setupFullAccount(userName: String, userColor: String, userID: Int, userAPIToken: String, providerUID: String, providerToken: String, successAddOn: completionClosure? = nil, failure: AFHTTPFailureBlock = defaultAFHTTPFailureBlockForServerDown) {
        
        OSAPI.sharedClient.POSTUserProvider(userName, userColor: userColor, userID: userID, userAPIToken: userAPIToken, providerUID: providerUID, providerToken: providerToken,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                
                // Update new user information
                if let newUserAPIToken = responseJSON["api_token"].string {
                    LocalUser.sharedUser.updateLocalUserInformationAfterSignIn(userID: userID, userAPIToken: newUserAPIToken, successAddOn: successAddOn, failure: failure)
                }
                
                // TODO: Handle possible errors
            },
            failure: defaultAFHTTPFailureBlockForServerDown
        )
    }
    
    
    func updateLocalUserInformationAfterSignIn(userID id: Int, userAPIToken token: String, successAddOn: completionClosure? = nil, failure: AFHTTPFailureBlock = defaultAFHTTPFailureBlockForServerDown) {
        // Download the user's record for the userID, update the LocalUser info from that json, 
        // update the UserDefaults, and update the Keychain info
        
        // Get the user's info from the server
        OSAPI.sharedClient.GETUser(id,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                
                // Update shared Local User's information, UserDefaults, and Keychain info
                LocalUser.sharedUser.updateLocalUserFromJSON(responseJSON, apiToken: token,
                    completion: {
                        // Save the accounts info in the keychain
                        self.updateKeychainInfoForLocalUser(id, userAPIToken: token)
                        // Send out LocalUserInformationDidChangeNotification
                        NSNotificationCenter.defaultCenter().postNotificationName(LocalUserInformationDidChangeNotification, object: nil)
                        
                        if successAddOn {
                            successAddOn!()
                        }
                    }
                )
            }, failure: failure
        )
    }
    
    func updateLocalUserFromJSON(json: JSONValue, apiToken: String, completion: completionClosure? = nil, fbUID: String? = nil, fbAuthToken: String? = nil) {
        println("Updating LocalUser from JSON")
        
        setup = true
        
        self.apiToken = apiToken
        self.facebookUID = fbUID
        self.facebookAuthenticationToken = fbAuthToken
        
        id = json["uid"].integer
        name = json["name"].string
        color = json["color"].string
        guest = json["guest"].bool
        songCount = json["song_count"].integer
        voteCount = json["vote_count"].integer
        followers = json["followers"].integer
        following = json["following"].integer
        
        if !guest && json["photo"].string && photoURL != json["photo"].string {
            // If not a guest and a non-empty photoURL gets sent that's different from what it was
            println("Setting new photo URL")
            photoURL = json["photo"].string
            downloadImageWithURLString(photoURL!,
                { success, image in
                    if success {
                        self.photo = image
                        println("Saved new photo for user")
                        NSUserDefaults.standardUserDefaults().setObject(UIImagePNGRepresentation(self.photo), forKey: userPhotoUIImageKey)
                    }
                }
            )
        }
        
        updateUserDefaultsForLocalUser()
        
        if completion {
            completion!()
        }
    }
    
    func updateLocalUserInformationFromServer() {
        // For updating the local user when NOT in the login flow
        printlnC(pL, pG, "Updating user information from server")
        
        OSAPI.sharedClient.GETUser(id,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                
                // Instantiate guest user from response JSON
                self.updateLocalUserFromJSON(responseJSON, apiToken: self.apiToken, fbUID: self.facebookUID, fbAuthToken:self.facebookAuthenticationToken)
                println(self.description())
            },
            failure: defaultAFHTTPFailureBlockForServerDown
        )
    }
    
    func updateUserDefaultsForLocalUser() {
        println("Updating information for LocalUser in UserDefaults")
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(name, forKey: userNameKey)
        defaults.setObject(color, forKey: userColorKey)
        defaults.setBool(guest, forKey: userGuestKey)
    }
    
    func updateKeychainInfoForLocalUser(userID: Int, userAPIToken: String) {
        // Save the account's info in the keychain
        println("Updating information for LocalUser in Keychain")
        println("Saved userID to keychain:\(userID)")
        println("Saved userAPIToken to keychain:\(userAPIToken)")
        
        SSKeychain.setPassword(String(userID), forService: service, account: userIDKeychainKey)
        SSKeychain.setPassword(userAPIToken, forService: service, account: userAPITokenKeychainKey)
    }
    
    func deleteAllSavedUserInformation(completion: completionClosure? = nil) {
        SSKeychain.deletePasswordForService(service, account: userIDKeychainKey)
        SSKeychain.deletePasswordForService(service, account: userAPITokenKeychainKey)
        SSKeychain.deletePasswordForService(service, account: userFacebookUIDKeychainKey)
        SSKeychain.deletePasswordForService(service, account: userFacebookAuthenticationTokenKeychainKey)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey(userNameKey)
        defaults.removeObjectForKey(userColorKey)
        defaults.removeObjectForKey(userGuestKey)
        defaults.removeObjectForKey(userPhotoUIImageKey)
        
        FBSession.activeSession().closeAndClearTokenInformation()
        
        if completion {
            completion!()
        }
    }
}
