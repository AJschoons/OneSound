//
//  PartySongCell.swift
//  OneSound
//
//  Created by adam on 8/15/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let PartySongCellNibName = "PartySongCell"

class PartySongCell: UITableViewCell {

    @IBOutlet weak var songName: THLabel!
    @IBOutlet weak var songArtist: THLabel!
    @IBOutlet weak var songImage: UIImageView!
    
    var songID: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        setupTHLabelToDefaultDesiredLook(songName)
        setupTHLabelToDefaultDesiredLook(songArtist)
        
        selectionStyle = UITableViewCellSelectionStyle.None
    }
}
