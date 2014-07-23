//
//  SideNavigationUserCell.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SideNavigationUserCell: UITableViewCell {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        userImage.layer.cornerRadius = 5
        
        // Stop cell color from changing when selected
        selectionStyle = UITableViewCellSelectionStyle.None
        
        refresh()
        
        // Make view respond to network reachability changes and user information changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
    }
    
    func refresh() {
        let user = LocalUser.sharedUser
        
        if user.setup {
            // If user exists
            userLabel.text = user.name
            
            if !user.guest && user.photo {
                // If user isn't a guest and has a valid photo
                userImage.image = user.photo
            } else {
                // If user guest or doesn't have valid photo
                userImage.backgroundColor = user.colorToUIColor
            }
        }
        else {
            // User isn't setup, check if any info saved in NSUserDefaults
            let defaults = NSUserDefaults.standardUserDefaults()
            let userSavedName = defaults.objectForKey(userNameKey) as? String
            let userSavedColor = defaults.objectForKey(userColorKey) as? String
            let userSavedIsGuest = defaults.boolForKey(userGuestKey)
            
            if userSavedName {
                // If user information can be retreived (assumes getting ANY user info means the rest is saved)
                userLabel.text = userSavedName
                if userSavedIsGuest {
                    if userSavedColor {
                        userImage.backgroundColor = LocalUser.colorToUIColor(userSavedColor!)
                    } else {
                        // In case the userSavedColor info can't be retrieved
                        userImage.backgroundColor = UIColor.grayDark()
                    }
                } else {
                    // Deal with non-guests here
                    let imageData = defaults.objectForKey(userGuestKey) as? NSData
                    if let image = UIImage(data: imageData) as UIImage? {
                        userImage.image = user.photo
                    } else {
                        // Couldn't get image
                        if userSavedColor {
                            userImage.backgroundColor = LocalUser.colorToUIColor(userSavedColor!)
                        } else {
                            // In case the userSavedColor info can't be retrieved
                            userImage.backgroundColor = UIColor.grayDark()
                        }
                    }
                    
                }
            } else {
                // Can't retrieve any user info
                userLabel.text = "Not Signed In"
                userImage.backgroundColor = UIColor.grayDark()
            }
        }
    }
}