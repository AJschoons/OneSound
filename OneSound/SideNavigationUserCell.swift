//
//  SideNavigationUserCell.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SideNavigationUserCell: UITableViewCell {

    @IBOutlet var userImage: UIImageView
    @IBOutlet var userLabel: UILabel
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        userImage.layer.cornerRadius = 5
        
        // Stop cell color from changing when selected
        selectionStyle = UITableViewCellSelectionStyle.None
        
        refresh()
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
    }
    
    func refresh() {
        let user = LocalUser.sharedUser
        
        if user.setup {
            // If user exists
            if user.guest {
                // If user is a guest
                userImage.backgroundColor = user.colorToUIColor
                userLabel.text = user.name
            }
        }
        else {
            // User isn't setup, check if any info saved in NSUserDefaults
            let defaults = NSUserDefaults.standardUserDefaults()
            let userSavedName = defaults.objectForKey("name") as? String
            let userSavedColor = defaults.objectForKey("color") as? String
            let userSavedIsGuest = defaults.boolForKey("guest")
            
            
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
                }
            } else {
                // Can't retrieve any user info
                userLabel.text = "Not Signed In"
                userImage.backgroundColor = UIColor.grayDark()
            }
        }
    }
}