//
//  UserFavoriteSongCell.swift
//  OneSound
//
//  Created by adam on 6/7/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

let UserFavoriteSongCellNibName = "UserFavoriteSongCell"

class UserFavoriteSongCell: SWTableViewCell
{    
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var songArtist: UILabel!
    @IBOutlet weak var songImage: UIImageView!
}
