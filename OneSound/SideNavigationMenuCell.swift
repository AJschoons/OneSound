//
//  SideNavigationMenuCell.swift
//  OneSound
//
//  Created by adam on 7/10/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class SideNavigationMenuCell: UITableViewCell {

    @IBOutlet var sideMenuItemIcon: UIImageView
    @IBOutlet var sideMenuItemLabel: UILabel
    var selectedIcon: UIImage?
    var unselectedIcon: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // Stop cell color from changing when selected
        selectionStyle = UITableViewCellSelectionStyle.None
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        if highlighted {
            sideMenuItemIcon.image = selectedIcon
            sideMenuItemLabel.textColor = UIColor.blue()
        } else {
            sideMenuItemIcon.image = unselectedIcon
            sideMenuItemLabel.textColor = UIColor.grayDark()
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if selected {
            sideMenuItemIcon.image = selectedIcon
            sideMenuItemLabel.textColor = UIColor.blue()
        } else {
            sideMenuItemIcon.image = unselectedIcon
            sideMenuItemLabel.textColor = UIColor.grayDark()
        }
    }
}
