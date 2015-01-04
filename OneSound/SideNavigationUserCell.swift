//
//  SideNavigationUserCell.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

// statusBar + navBar + 10 spacing + 100 height + 2 for good measure
let sideNavigationUserCellUserImageBottomDisanceFromTop: CGFloat = (20 + 64 + 10 + 100 + 2)
let userImageDistanceFromTopOfSideNavigationUserCell: CGFloat = 10

class SideNavigationUserCell: UITableViewCell {

    //@IBOutlet weak var userImage: UIImageView! // Moved to ENSideMenu so wouldn't get vibrancy effect as table subview
    //@IBOutlet weak var blurredUserImage: UIImageView! // Removed after blurred side menu added
    @IBOutlet weak var userLabel: UILabel!
    
    var userImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        userImage = getFrontNavigationController()?.sideMenu?.userImage
        userImage.layer.cornerRadius = 5
        //userImage.layer.borderColor = UIColor.black().CGColor
        //userImage.layer.borderWidth = 1.0
        userImage.clipsToBounds = true
        
        backgroundColor = UIColor.clearColor()
        
        // Stop cell color from changing when selected
        selectionStyle = UITableViewCellSelectionStyle.None
        
        refresh()
        
        // Make view respond to network reachability changes and user information changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: UserManagerInformationDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: FacebookSessionChangeNotification, object: nil)
    }
    
    func refresh() {
        println("refreshing SideNavigationUserCell")
        
        if UserManager.sharedUser.setup == true {
            // If user exists
            println("user is setup")
            let userName = UserManager.sharedUser.name
            userLabel.text = userName
            
            if UserManager.sharedUser.guest == false && UserManager.sharedUser.photo != nil {
                // If user isn't a guest and has a valid photo
                println("full user with valid photo; use their photo")
                userImage.image = UserManager.sharedUser.photo
            } else {
                // If user guest or doesn't have valid photo
                println("guest user or invalid photo, use user color")
                userImage.image = nil
                userImage.backgroundColor = UserManager.sharedUser.colorToUIColor
                
            }
        }
        else {
            // User isn't setup, check if any info saved in NSUserDefaults
            println("user isn't setup")
            let defaults = NSUserDefaults.standardUserDefaults()
            let userSavedName = defaults.objectForKey(userNameKey) as? String
            let userSavedColor = defaults.objectForKey(userColorKey) as? String
            let userSavedIsGuest = defaults.boolForKey(userGuestKey)
            
            if userSavedName != nil {
                // If user information can be retreived (assumes getting ANY user info means the rest is saved)
                println("found user info in user defaults")
                userLabel.text = userSavedName
                if userSavedIsGuest {
                    println("saved user was guest")
                    userImage.image = nil
                    
                    if userSavedColor != nil {
                        userImage.backgroundColor = UserManager.colorToUIColor(userSavedColor!)
                    } else {
                        // In case the userSavedColor info can't be retrieved
                        userImage.backgroundColor = UIColor.grayDark()
                    }
                } else {
                    // Deal with non-guests here
                    println("found full user info in user defaults")
                    if let imageData = defaults.objectForKey(userPhotoUIImageKey) as? NSData! {
                        if imageData != nil {
                            println("image data valid, use their image")
                            let image = UIImage(data: imageData)
                            userImage.image = image
                            
                            var blurredImage = image!.applyBlurWithRadius(2, tintColor: nil, saturationDeltaFactor: 1.3, maskImage: nil)
                        } else {
                            println("image data valid but was nil, try using their color")
                            userImage.image = nil
                            
                            if userSavedColor != nil  {
                                userImage.backgroundColor = UserManager.colorToUIColor(userSavedColor!)
                            } else {
                                // In case the userSavedColor info can't be retrieved
                                userImage.backgroundColor = UIColor.grayDark()
                            }
                        }
                    } else {
                        // Couldn't get image
                        println("image data invalid, use their color")
                        userImage.image = nil
                        
                        if userSavedColor != nil  {
                            userImage.backgroundColor = UserManager.colorToUIColor(userSavedColor!)
                        } else {
                            // In case the userSavedColor info can't be retrieved
                            userImage.backgroundColor = UIColor.grayDark()
                        }
                    }
                }
            } else {
                // Can't retrieve any user info
                println("user isn't setup")
                userLabel.text = "Not Signed In"
                userImage.image = nil
                userImage.backgroundColor = UIColor.grayDark()
            }
        }
    }
}