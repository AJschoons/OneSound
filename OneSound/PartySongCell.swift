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
        songName.textInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        songArtist.textInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        
        selectionStyle = UITableViewCellSelectionStyle.None
    }
}
