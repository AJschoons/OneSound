//
//  AppUser.swift
//  OneSound
//
//  Created by adam on 7/17/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation

let LocalUserDidGetSetupNotification = "LocalUserDidGetSetup"
let service = "com.AdamSchoonmaker.OneSound"
let userIDKeychainKey = "userID"
let userAPITokenKeychainKey = "userAPIToken"
let userFacebookUIDKeychainKey = "userFacebookUID"
let userFacebookAuthenticationTokenKeychainKey = "userFacebookAuthenticationTokenKey"
let userNameKey = "name"
let userColorKey = "color"
let userGuestKey = "guest"

class LocalUser {
    
    var setup = false
    var pL = true
    
    var apiToken: String!
    var facebookUID: String?
    var facebookAuthenticationToken: String?
    
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
        println("randon int for color:\(randomInt)")
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
        var d = "[USER] id:\(id) name:'\(name)' color:\(color) guest:\(guest) f-ers:\(followers) f-ing:\(following) songs:\(songCount) votes:\(voteCount) photo:\(photo) apiToken: \(apiToken)"
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
    
    func fetchLocalGuestUser(id: Int, apiToken: String) {
        // For use in the login flow of signing a user in
        
        printlnC(pL, pG, "app has GUEST with userID:\(id)")
        printlnC(pL, pG, "app has GUEST with userAPIToken:\(apiToken)")
        
        OSAPI.sharedClient.GETUser(id,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                
                // Instantiate guest user from response JSON
                self.updateLocalUserFromJSON(responseJSON, apiToken: apiToken, fbUID: nil, fbAuthToken: nil)
                println(self.description())
                
                // Update the guest user's defaults after fetching
                self.updateUserDefaultsForLocalUser()
                
                // Send out LocalUserDidGetSetup notification
                NSNotificationCenter.defaultCenter().postNotificationName(LocalUserDidGetSetupNotification, object: nil)
            },
            failure: { task, error in
                println("ERROR: Guest account no longer exists, creating new one")
                println(error.localizedDescription)
                self.setupLocalGuestUser()
            }
        )
    }
    
    func setupLocalGuestUser() {
        // For use in the login flow of signing a user in
        
        printlnC(pL, pG, "app has no userID or guest, request GUEST user")
        
        // Get the guest user creation info from the server
        OSAPI.sharedClient.GETGuestUser(
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                
                // Get the guest response info
                let guestAPIToken = responseJSON["api_token"].string
                let guestUID = responseJSON["uid"].integer
                let guestName = responseJSON["name"].string
                
                // Get the new guest user info from the server after color updated
                // Set that as the localUser, save their userID and userAPIToken in the keychain
                OSAPI.sharedClient.GETUser(guestUID!,
                    success: { data, responseObject in
                        let responseJSON = JSONValue(responseObject)
                        println(responseJSON)
                        
                        // Instantiate guest user from response JSON
                        self.updateLocalUserFromJSON(responseJSON, apiToken: guestAPIToken!, fbUID: nil, fbAuthToken: nil)
                        println(self.description())
                        
                        printlnC(self.pL, pG, "CREATED GUEST userID:\(guestUID)")
                        printlnC(self.pL, pG, "CREATED GUEST userAPIToken:\(guestAPIToken)")
                        
                        // Save the new guest's info in NSUserDefaults
                        self.updateUserDefaultsForLocalUser()
                        
                        // Save the new guest's info in the keychain
                        SSKeychain.setPassword(String(guestUID!), forService: service, account: userIDKeychainKey)
                        SSKeychain.setPassword(guestAPIToken, forService: service, account: userAPITokenKeychainKey)
                        
                        // Send out LocalUserDidGetSetup notification
                        NSNotificationCenter.defaultCenter().postNotificationName(LocalUserDidGetSetupNotification, object: nil)
                    },
                    failure: defaultAFHTTPFailureBlockForServerDown
                )
            },
            failure: defaultAFHTTPFailureBlockForServerDown
        )
    }
    
    func setupLocalFullUserFromGuestAccount(fbUID: String, fbAuthToken: String) {
        printlnC(pL, pG, "upgrading guest to full account")
        
        OSAPI.sharedClient.GETUserLoginProvider(fbUID, providerToken: fbAuthToken,
            success: { data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)

            }, failure: defaultAFHTTPFailureBlockForServerDown
        )
    }
    
    func updateLocalUserFromJSON(json: JSONValue, apiToken: String, fbUID: String? = nil, fbAuthToken: String? = nil) {
        setup = true
        
        self.apiToken = apiToken
        self.facebookUID = fbUID
        self.facebookAuthenticationToken = fbAuthToken
        
        id = json["uid"].integer
        name = json["name"].string
        color = json["color"].string
        guest = json["guest"].bool
        photoURL = json["photo"].string
        songCount = json["song_count"].integer
        voteCount = json["vote_count"].integer
        followers = json["followers"].integer
        following = json["following"].integer
    }
    
    func updateLocalUserInformationFromServer() {
        // For updating the local user when NOT in the login flow
        printlnC(pL, pG, "updating user information from server")
        
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
        println("updating information for LocalUser in UserDefaults")
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(name, forKey: userNameKey)
        defaults.setObject(color, forKey: userColorKey)
        defaults.setBool(guest, forKey: userGuestKey)
        if !guest {
            // Save the photo information
        }
    }
    
    func deleteAllSavedUserInformation() {
        SSKeychain.deletePasswordForService(service, account: userIDKeychainKey)
        SSKeychain.deletePasswordForService(service, account: userAPITokenKeychainKey)
        SSKeychain.deletePasswordForService(service, account: userFacebookUIDKeychainKey)
        SSKeychain.deletePasswordForService(service, account: userFacebookAuthenticationTokenKeychainKey)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey(userNameKey)
        defaults.removeObjectForKey(userColorKey)
        defaults.removeObjectForKey(userGuestKey)
        
        FBSession.activeSession().closeAndClearTokenInformation()
    }
}
