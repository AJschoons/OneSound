//
//  PartySongCell.swift
//  OneSound
//
//  Created by adam on 8/15/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let PartySongCellNibName = "PartySongCell"

protocol PartySongCellDelegate: class {
    func didVoteOnSongCellAtIndex(index: Int, withVote vote: SongVote, andVoteCountChange voteCountChange: Int)
}

class PartySongCell: SWTableViewCell {

    @IBOutlet private(set) weak var songName: UILabel!
    @IBOutlet weak var songArtist: UILabel!
    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var thumbsDownButton: UIButton!
    @IBOutlet weak var thumbsUpButton: UIButton!
    @IBOutlet weak var thumbsDownImage: UIImageView!
    @IBOutlet weak var thumbsUpImage: UIImageView!
    
    @IBOutlet weak private(set) var triangleView: OSTriangleView!
    @IBOutlet weak private(set) var voteCountLabel: UILabel!
    
    // Used for tracking where cell is for votes (need a way to "talk" to the tableViewController)
    weak var voteDelegate: PartySongCellDelegate?
    var index: Int?
    
    private var voteCountIsNegative = false
    
    @IBAction func onThumbsDown(sender: AnyObject) {
        handleThumbsDown(sender)
    }
    
    @IBAction func onThumbsUp(sender: AnyObject) {
        handleThumbsUp(sender)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // (From when these were THLabels in the old design)
        //setupTHLabelToDefaultDesiredLook(songName)
        //setupTHLabelToDefaultDesiredLook(songArtist)
        //songName.textInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        //songArtist.textInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        
        songImage.layer.cornerRadius = 3.0
        songImage.layer.masksToBounds = true
        
        selectionStyle = UITableViewCellSelectionStyle.None
    }
    
    // Sets the vote count label and triangle color
    func setVoteCount(count: Int) {
        voteCountIsNegative = false // Initialize it to non-negative
        
        var triangleColor: UIColor
        if count > 0 { triangleColor = UIColor.green() }
        else if count == 0 { triangleColor = UIColor.orange() }
        else { triangleColor = UIColor.red(); voteCountIsNegative = true }
        triangleView.color = triangleColor
        triangleView.setNeedsDisplay() // Force it to redraw

        voteCountLabel.text = intFormattedToShortStringForDisplay(abs(count))
    }
    
    private func changeSongVoteCountLabelCountBy(changeBy: Int) {
        if var voteCount = voteCountLabel.text!.toInt() {
            if voteCountIsNegative { voteCount = -voteCount }
            let newVoteCount = voteCount + changeBy
            setVoteCount(newVoteCount)
        }
    }
}

extension PartySongCell {
    // MARK: Thumbs up/down button handling
    
    func setThumbsUpDownButtons(thumbsUp: Bool, thumbsDown: Bool) {
        if thumbsUp {
            setThumbsUpSelected()
            setThumbsDownUnselected()
        } else if thumbsDown {
            setThumbsDownSelected()
            setThumbsUpUnselected()
        } else {
            resetThumbsUpDownButtons()
        }
    }
    
    func handleThumbsUp(button: AnyObject) {
        if let thumbsUpButton = button as? UIButton {
            var vote: SongVote
            var voteCountChange: Int
            
            // If the button is selected before it is pressed, make it unselected
            if thumbsUpButton.selected {
                vote = .Clear // Clear song vote on the server
                voteCountChange = -1
                setThumbsUpUnselected()
            
            // If the button is unselected before it is pressed
            } else {
                vote = .Up // Upvote song on the server
                setThumbsUpSelected()
                
                // If the thumbs down button is already selected when thumbs up gets selected, unselect it
                if thumbsDownButton.selected {
                    voteCountChange = 2
                    setThumbsDownUnselected()
                // Thumbs down button wasn't already selected when thumbs up gets selected
                } else {
                    voteCountChange = 1
                }
            }
            
            // Update the vote count on the label, playlistManager, and server
            changeSongVoteCountLabelCountBy(voteCountChange)
            if index != nil {
                voteDelegate?.didVoteOnSongCellAtIndex(index!, withVote: vote, andVoteCountChange: voteCountChange)
            }
        }
    }
    
    func handleThumbsDown(button: AnyObject) {
        if let thumbsDownButton = button as? UIButton {
            var vote: SongVote
            var voteCountChange: Int
            
            // If the button is selected before it is pressed, make it unselected
            if thumbsDownButton.selected {
                vote = .Clear // Clear song vote on the server
                voteCountChange = 1
                setThumbsDownUnselected()
                
            // If the button is unselected before it is pressed
            } else {
                vote = .Down
                setThumbsDownSelected()
                
                // If the thumbs up button is already selected when thumbs down gets selected, unselect it
                if thumbsUpButton.selected {
                    setThumbsUpUnselected()
                    voteCountChange = -2
                // Thumbs up button wasn't already selected when thumbs down gets selected
                } else {
                    voteCountChange = -1
                }
            }
            
            // Update the vote count on the label, PlaylistManager, and server
            changeSongVoteCountLabelCountBy(voteCountChange)
            if index != nil {
                voteDelegate?.didVoteOnSongCellAtIndex(index!, withVote: vote, andVoteCountChange: voteCountChange)
            }
        }
    }
    
    func resetThumbsUpDownButtons() {
        setThumbsUpUnselected()
        setThumbsDownUnselected()
    }
    
    func setThumbsUpSelected() {
        thumbsUpImage.image = thumbsUpSelectedMainParty
        thumbsUpButton.selected = true
    }
    
    private func setThumbsUpUnselected() {
        thumbsUpImage.image = thumbsUpUnselectedMainParty
        thumbsUpButton.selected = false
    }
    
    func setThumbsDownSelected() {
        thumbsDownImage.image = thumbsDownSelectedMainParty
        thumbsDownButton.selected = true
    }
    
    private func setThumbsDownUnselected() {
        thumbsDownImage.image = thumbsDownUnselectedMainParty
        thumbsDownButton.selected = false
    }
}
