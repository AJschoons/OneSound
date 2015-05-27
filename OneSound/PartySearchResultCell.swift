//
//  PartySearchResultCell.swift
//  OneSound
//
//  Created by adam on 12/13/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let PartySearchResultCellNibName = "PartySearchResultCell"

class PartySearchResultCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var memberCountLabel: UILabel!
    @IBOutlet weak var locationImage: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
