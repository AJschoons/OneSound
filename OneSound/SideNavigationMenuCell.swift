//
//  SideNavigationMenuCell.swift
//  OneSound
//
//  Created by adam on 7/10/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SideNavigationMenuCell: UITableViewCell {

    @IBOutlet weak var sideMenuItemIcon: UIImageView!
    @IBOutlet weak var sideMenuItemLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // Stop cell color from changing when selected
        selectionStyle = UITableViewCellSelectionStyle.None
        
        if ObjCUtilities.checkIfClassExists("UIVisualEffectView") {
            // iOS 8 has blurred menu
            sideMenuItemLabel.textColor = UIColor.black()
        } else {
            // iOS 7 has static white menu
            sideMenuItemLabel.textColor = UIColor.grayDark()
        }
    }
}
