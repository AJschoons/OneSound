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
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
