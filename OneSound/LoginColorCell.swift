//
//  LoginColorCell.swift
//  OneSound
//
//  Created by adam on 7/16/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class LoginColorCell: UITableViewCell {
    @IBOutlet var colorLabel: UILabel
    @IBOutlet var colorView: UIView
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        colorView.layer.cornerRadius = 3
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
