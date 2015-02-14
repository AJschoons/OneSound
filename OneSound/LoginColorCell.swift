//
//  LoginColorCell.swift
//  OneSound
//
//  Created by adam on 7/16/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class LoginColorCell: UITableViewCell {
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        colorView.layer.cornerRadius = 3
    }
}