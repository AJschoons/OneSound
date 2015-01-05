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

    @IBOutlet private(set) weak var songName: UILabel!
    @IBOutlet weak var songArtist: UILabel!
    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var thumbsDownButton: UIButton!
    @IBOutlet weak var thumbsUpButton: UIButton!
    
    @IBOutlet weak private var triangleView: OSTriangleView!
    @IBOutlet weak private var voteCountLabel: UILabel!
    
    var songID: Int!
    
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
        var triangleColor: UIColor
        if count > 0 { triangleColor = UIColor.green() }
        else if count == 0 { triangleColor = UIColor.orange() }
        else { triangleColor = UIColor.red() }
        triangleView.color = triangleColor
        triangleView.setNeedsDisplay() // Force it to redraw

        voteCountLabel.text = intFormattedToShortStringForDisplay(abs(count))
    }
    
    func handleThumbsUp(button: AnyObject) {
        if let thumbsUpButton = button as? UIButton {
            if thumbsUpButton.selected {
                // If the button is selected before it is pressed, make it unselected
                setThumbsUpUnselected()
                
                // Clear song vote on the server
                PartyManager.sharedParty.songClearVote(songID)
            } else {
                // If the button is unselected before it is pressed
                setThumbsUpSelected()
                
                // Upvote song on the server
                PartyManager.sharedParty.songUpvote(songID)
                
                // If the thumbs down button is already selected when thumbs up gets selected, unselect it
                if thumbsDownButton.selected {
                    setThumbsDownUnselected()
                }
            }
        }
    }
    
    func handleThumbsDown(button: AnyObject) {
        if let thumbsDownButton = button as? UIButton {
            if thumbsDownButton.selected {
                // If the button is selected before it is pressed, make it unselected
                setThumbsDownUnselected()
                
                // Clear song vote on the server
                PartyManager.sharedParty.songClearVote(songID)
            } else {
                // If the button is unselected before it is pressed
                setThumbsDownSelected()
                
                // Downvote song on the server
                PartyManager.sharedParty.songDownvote(songID)
                
                // If the thumbs up button is already selected when thumbs down gets selected, unselect it
                if thumbsUpButton.selected {
                    setThumbsUpUnselected()
                }
            }
        }
    }
    
    func resetThumbsUpDownButtons() {
        setThumbsUpUnselected()
        setThumbsDownUnselected()
    }
    
    func setThumbsUpSelected() {
        thumbsUpButton.setImage(thumbsUpSelectedMainParty, forState: UIControlState.Normal)
        thumbsUpButton.selected = true
    }
    
    func setThumbsUpUnselected() {
        thumbsUpButton.setImage(thumbsUpUnselectedMainParty, forState: UIControlState.Normal)
        thumbsUpButton.selected = false
    }
    
    func setThumbsDownSelected() {
        thumbsDownButton.setImage(thumbsDownSelectedMainParty, forState: UIControlState.Normal)
        thumbsDownButton.selected = true
    }
    
    func setThumbsDownUnselected() {
        thumbsDownButton.setImage(thumbsDownUnselectedMainParty, forState: UIControlState.Normal)
        thumbsDownButton.selected = false
    }
}
