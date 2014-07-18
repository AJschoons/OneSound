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
        
        refreshUserInformation()
    }
    
    func refreshUserInformation() {
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
            userImage.backgroundColor = UIColor.grayDark()
            userLabel.text = "Not Signed In"
        }
    }
    
}
