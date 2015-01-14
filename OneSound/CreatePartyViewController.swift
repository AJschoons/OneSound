//
//  CreatePartyViewController.swift
//  OneSound
//
//  Created by adam on 8/13/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let CreatePartyViewControllerIdentifier = "CreatePartyViewController"
let CreatePartyStoryboardName = "CreateParty"

protocol CreatePartyViewControllerDelegate {
    func CreatePartyViewControllerDone()
}

class CreatePartyViewController: UITableViewController {
        
    let validCharacters = "abcdefghijklmnopqrstuvwxyz1234567890 "
    var footerViewHeight = 125
    
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var nameCellTextField: UITextField!
    @IBOutlet weak var nameCellTextFieldCount: UILabel!
    @IBOutlet weak var privacyCell: UITableViewCell!
    var privacyCellSwitch: UISwitch!
    @IBOutlet weak var strictnessCell: UITableViewCell!
    @IBOutlet weak var strictnessCellStrictnessLabel: UILabel!
    
    var streamControlButton: UIButton?
    let scButtonTitleEnabled = "Control Music Stream"
    let scButtonTitleDisabled = "Controlling Music Stream"
    let scButtonTextColorEnabled = UIColor.white()
    let scButtonTextColorDisabled = UIColor.grayLight()
    let scButtonBGColorEnabled = UIColor.blue()
    let scButtonBGColorDisabled = UIColor.grayMid()
    
    var skipSongButton: UIButton?
    let skipButtonTitle = "Skip Playing Song"
    let skipButtonTextColorEnabled = UIColor.white()
    let skipButtonTextColorDisabled = UIColor.grayLight()
    let skipButtonBGColorEnabled = UIColor.red()
    let skipButtonBGColorDisabled = UIColor.grayMid()
    
    var leavePartyButton: UIButton?
    
    var strictness: PartyStrictnessOption = .Default
    var partyAlreadyExists = false
    
    var delegate: CreatePartyViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup nav bar
        if partyAlreadyExists {
            navigationItem.title = "Party Settings"
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "cancel")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Update", style: UIBarButtonItemStyle.Done, target: self, action: "done")
        } else {
            navigationItem.title = "Create Party"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "done")
        }
        navigationItem.rightBarButtonItem!.enabled = false
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "navigationBarBackground"), forBarMetrics: UIBarMetrics.Default)
        navigationController?.navigationBar.shadowImage = UIImage(named: "navigationBarShadow")
        navigationController?.navigationBar.tintColor = UIColor.blue()
        navigationController?.navigationBar.barTintColor = UIColor.white()
        navigationController?.navigationBar.translucent = true
        navigationController?.navigationBar
        
        // Stop view from being covered by the nav bar / laid out from top of screen
        edgesForExtendedLayout = UIRectEdge.None
        
        // Initialize the text field's delegate and character count label
        nameCellTextField.delegate = self
        nameCellTextField.addTarget(self, action: "textFieldDidChange", forControlEvents: UIControlEvents.EditingChanged)
        updateNameCellTextFieldCount()
        
        // TODO: Initialize cells that need to be (privacy)
        if partyAlreadyExists {
            if let previousStrictness = PartyStrictnessOption(rawValue: PartyManager.sharedParty.strictness) {
                strictness = previousStrictness
            }
        }
        strictnessCellStrictnessLabel.text = strictness.PartyStrictnessOptionToString()
        
        // Give the name text field the party's name if it already exists
        if partyAlreadyExists {
            nameCellTextField.text = PartyManager.sharedParty.name
            updateNameCellTextFieldCount()
        }
        
        if partyAlreadyExists {
            // Add a tableView footer with a button to leave the party
            setupButtonsInTableFooterView()
        }
        
        // Give the privacy cell a switch
        let selectionSwitch = UISwitch()
        selectionSwitch.onTintColor = UIColor.blue()
        privacyCell.accessoryView = selectionSwitch
        privacyCellSwitch = selectionSwitch
        
        // Add tap gesture recognizer to dismiss keyboard when background touched
        // Make sure the tap doesn't interfere with touches in the table view
        let tap = UITapGestureRecognizer(target: self, action: "tap")
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
        
        // Dismiss when the party state changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onSuccessfulPartyCreateOrUpdateOrLeave", name: PartyManagerStateChangeNotification, object: nil)
    }
    
    func cancel() {
        tableView.endEditing(true)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func done() {
        if !partyAlreadyExists {
            println("Creating NEW party")
            PartyManager.sharedParty.createNewParty(nameCellTextField.text, privacy: privacyCellSwitch.on, strictness: strictness.rawValue,
                respondToChangeAttempt: { partyWasCreated in
                    if partyWasCreated {
                        self.onSuccessfulPartyCreateOrUpdateOrLeave()
                    } else {
                        let alert = UIAlertView(title: "Could not create party", message: "Please try a new name, changing the settings, or restarting the app", delegate: nil, cancelButtonTitle: "Ok")
                        alert.show()
                    }
                }
            )
        } else {
            println("updating party information")
            PartyManager.sharedParty.changePartyInfo(nameCellTextField.text, privacy: privacyCellSwitch.on, strictness: strictness.rawValue,
                respondToChangeAttempt: { partyWasUpdated in
                    if partyWasUpdated {
                        self.onSuccessfulPartyCreateOrUpdateOrLeave()
                    } else {
                        let alert = UIAlertView(title: "Could not update party", message: "Please try a new name, changing the settings, or restarting the app", delegate: nil, cancelButtonTitle: "Ok")
                        alert.show()
                    }
                }
            )
        }
    }
    
    func onSuccessfulPartyCreateOrUpdateOrLeave() {
        self.tableView.endEditing(true)
        self.dismissViewControllerAnimated(true, completion: nil)
        
        if PartyManager.sharedParty.state != .None {
            getAppDelegate().sideMenuViewController.programaticallySelectRow(1)
        }
        
        if self.delegate != nil {
            self.delegate!.CreatePartyViewControllerDone()
        }
    }
    
    func leaveParty() {
        // "Leave" handled in the UIAlertViewDelegate extension
        let alert = UIAlertView(title: "Leaving Party as Host", message: "Leaving a party you're hosting will stop the party from playing music for everyone else. You can always join back, but don't leave if you want it to keep going", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Leave")
        alert.tag = 103
        alert.show()
    }
    
    func skipSong() {
        PartyManager.sharedParty.audioManager.onSongSkip()
        onSuccessfulPartyCreateOrUpdateOrLeave()
    }
    
    func controlMusicStream() {
        PartyManager.sharedParty.getMusicStreamControl(respondToChangeAttempt: { success in
            if success {
                // Now that there is streaming control, update the buttons
                self.streamControlButton?.backgroundColor = self.scButtonBGColorDisabled
                self.streamControlButton?.enabled = false
                self.skipSongButton?.backgroundColor = self.skipButtonBGColorEnabled
                self.skipSongButton?.enabled = true
                delayOnMainQueueFor(numberOfSeconds: 0.5, action: {
                    self.onSuccessfulPartyCreateOrUpdateOrLeave()
                })
            } else {
                let alert = UIAlertView(title: "Music Control Failure", message: "Failed to get the music stream control. Please reload the party settings and try again", delegate: self, cancelButtonTitle: "Okay")
                alert.show()
            }
        })
    }
    
    func textFieldDidChange() {
        updateNameCellTextFieldCount()
        setDoneButtonState()
    }
    
    func setDoneButtonState() {
        if partyAlreadyExists {
            // Only allow Done to be pressed if party information has changed from what is already is
            // TODO: add in a check for privacy info change
            if countElements(nameCellTextField.text as String) > 2 && partyInfoHasChanged() {
                navigationItem.rightBarButtonItem!.enabled = true
            } else {
                navigationItem.rightBarButtonItem!.enabled = false
            }
        } else {
            if countElements(nameCellTextField.text as String) > 2 {
                navigationItem.rightBarButtonItem!.enabled = true
            } else {
                navigationItem.rightBarButtonItem!.enabled = false
            }
        }
    }
    
    func partyInfoHasChanged() -> Bool {
        // TODO: add in a check for privacy info change
        let party = PartyManager.sharedParty
        return (nameCellTextField.text != party.name) || (strictness.rawValue != party.strictness)
    }
    
    func updateNameCellTextFieldCount() {
        let numberOfCharacters = countElements(nameCellTextField.text as String)
        
        // Update label
        nameCellTextFieldCount.text = "\(numberOfCharacters)/20"
        
        // Change color based on number of characters
        switch numberOfCharacters {
        case 0...2:
            nameCellTextFieldCount.textColor = UIColor.red()
        case 3...15:
            nameCellTextFieldCount.textColor = UIColor.green()
        case 15...17:
            nameCellTextFieldCount.textColor = UIColor.orange()
        case 18...20:
            nameCellTextFieldCount.textColor = UIColor.red()
        default:
            nameCellTextFieldCount.textColor = UIColor.black()
        }
    }
    
    func tap() {
        // Dismiss the keyboard whenever the background is touched while editing
        tableView.endEditing(true)
    }
    
    // footerViewHeight = 95
    func setupButtonsInTableFooterView() {
        let footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.width, CGFloat(footerViewHeight)))
        footerView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = footerView
        
        let partyManger = PartyManager.sharedParty
        let userIsHostStreamable = (partyManger.state == .HostStreamable)
        let userIsHost = (partyManger.state == .Host)
        
        let streamControlButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.streamControlButton = streamControlButton
        let streamControlButtonEnabled = userIsHost
        streamControlButton.setTitle(scButtonTitleEnabled, forState: UIControlState.Normal)
        streamControlButton.setTitle(scButtonTitleDisabled, forState: UIControlState.Disabled)
        streamControlButton.setTitleColor(scButtonTextColorEnabled, forState: UIControlState.Normal)
        streamControlButton.setTitleColor(scButtonTextColorDisabled, forState: UIControlState.Disabled)
        let scButtonBGColor = (streamControlButtonEnabled) ? scButtonBGColorEnabled : scButtonBGColorDisabled
        streamControlButton.backgroundColor = scButtonBGColor
        streamControlButton.addTarget(self, action: "controlMusicStream", forControlEvents: UIControlEvents.TouchUpInside)
        streamControlButton.titleLabel!.textAlignment = NSTextAlignment.Center
        streamControlButton.titleLabel!.font = UIFont.systemFontOfSize(15)
        streamControlButton.layer.cornerRadius = 3.0
        streamControlButton.enabled = streamControlButtonEnabled
        streamControlButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let skipSongButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.skipSongButton = skipSongButton
        let skipSongButtonEnabled = userIsHostStreamable
        skipSongButton.setTitle(skipButtonTitle, forState: UIControlState.Normal)
        skipSongButton.setTitle(skipButtonTitle, forState: UIControlState.Disabled)
        skipSongButton.setTitleColor(skipButtonTextColorEnabled, forState: UIControlState.Normal)
        skipSongButton.setTitleColor(skipButtonTextColorDisabled, forState: UIControlState.Disabled)
        let skipButtonBGColor = (skipSongButtonEnabled) ? skipButtonBGColorEnabled : skipButtonBGColorDisabled
        skipSongButton.backgroundColor = skipButtonBGColor
        skipSongButton.addTarget(self, action: "skipSong", forControlEvents: UIControlEvents.TouchUpInside)
        skipSongButton.titleLabel!.textAlignment = NSTextAlignment.Center
        skipSongButton.titleLabel!.font = UIFont.systemFontOfSize(15)
        skipSongButton.layer.cornerRadius = 3.0
        skipSongButton.enabled = skipSongButtonEnabled
        skipSongButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let leavePartyButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        self.leavePartyButton = leavePartyButton
        leavePartyButton.setTitle("Leave Party", forState: UIControlState.Normal)
        leavePartyButton.setTitleColor(UIColor.white(), forState: UIControlState.Normal)
        leavePartyButton.addTarget(self, action: "leaveParty", forControlEvents: UIControlEvents.TouchUpInside)
        leavePartyButton.backgroundColor = UIColor.red()
        //leavePartyButton.titleLabel!.textColor = UIColor.white()
        leavePartyButton.titleLabel!.textAlignment = NSTextAlignment.Center
        leavePartyButton.titleLabel!.font = UIFont.systemFontOfSize(15)
        leavePartyButton.layer.cornerRadius = 3.0
        leavePartyButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        footerView.addSubview(streamControlButton)
        footerView.addSubview(skipSongButton)
        footerView.addSubview(leavePartyButton)
        
        streamControlButton.addConstraint(NSLayoutConstraint(item: streamControlButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 30))
        footerView.addConstraint(NSLayoutConstraint(item: streamControlButton, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 15))
        footerView.addConstraint(NSLayoutConstraint(item: streamControlButton, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: -15))
        footerView.addConstraint(NSLayoutConstraint(item: streamControlButton, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: skipSongButton, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: -10))
        
        skipSongButton.addConstraint(NSLayoutConstraint(item: skipSongButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 30))
        footerView.addConstraint(NSLayoutConstraint(item: skipSongButton, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 15))
        footerView.addConstraint(NSLayoutConstraint(item: skipSongButton, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: -15))
        footerView.addConstraint(NSLayoutConstraint(item: skipSongButton, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: leavePartyButton, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: -10))
        
        leavePartyButton.addConstraint(NSLayoutConstraint(item: leavePartyButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 30))
        footerView.addConstraint(NSLayoutConstraint(item: leavePartyButton, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 15))
        footerView.addConstraint(NSLayoutConstraint(item: leavePartyButton, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: -15))
        footerView.addConstraint(NSLayoutConstraint(item: leavePartyButton, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
    }
    
    /*
    // Before adding other buttons
    // footerViewHeight = 60 back then, btw
    func setupButtonsInTableFooterView() {
        let footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.width, CGFloat(footerViewHeight)))
        footerView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = footerView
        
        let button = UIButton.buttonWithType(UIButtonType.System) as UIButton
        button.setTitle("Leave Party", forState: UIControlState.Normal)
        button.setTitleColor(UIColor.white(), forState: UIControlState.Normal)
        button.addTarget(self, action: "leaveParty", forControlEvents: UIControlEvents.TouchUpInside)
        button.titleLabel!.textColor = UIColor.white()
        button.titleLabel!.textAlignment = NSTextAlignment.Center
        button.titleLabel!.font = UIFont.systemFontOfSize(15)
        button.backgroundColor = UIColor.red()
        button.layer.cornerRadius = 3.0
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        footerView.addSubview(button)
        
        button.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 30))
        footerView.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 15))
        footerView.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: -15))
        footerView.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
    }*/
}

extension CreatePartyViewController: UITableViewDataSource {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return nameCell
        case 1:
            return privacyCell
        case 2:
            return strictnessCell
        default:
            println("Error: LoginViewController cellForRowAtIndexPath couldn't get cell")
            return UITableViewCell()
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
}

extension CreatePartyViewController: UITableViewDelegate {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            // Selecting anywhere in the first cell will start editing text field
            // Otherwise would be weird b/c must touch UITextField but design makes it look otherwise
            nameCellTextField.becomeFirstResponder()
        case 2:
            let createPartyStrictnessViewController = CreatePartyStrictnessViewController(delegate: self, selectedStrictness: strictness)
            navigationController!.pushViewController(createPartyStrictnessViewController, animated: true)
        default:
            return
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 2 // Only highlight the party strictness cell
    }
}

extension CreatePartyViewController: UITextFieldDelegate {
    func textField(textField: UITextField!, shouldChangeCharactersInRange range: NSRange, replacementString string: String!) -> Bool {
        // Returns false if any of the replacementString characters are invalid
        for c in string {
            if !validCharacters.hasSubstringCaseInsensitive(String(c)) {
                return false
            }
        }
        
        if addingOnlyWhitespaceToTextFieldWithOnlyWhitespaceOrEmpty(textField.text, string) {
            return false
        }
        
        // Only allow change if 20 or less characters
        let newLength = countElements(textField.text as String) + countElements(string as String) - range.length
        return ((newLength > 20) ? false : true)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        // Hide keyboard when user presses "Done"
        removeLeadingWhitespaceFromTextField(&nameCellTextField!)
        nameCellTextField.resignFirstResponder()
        return true
    }
}

extension CreatePartyViewController: CreatePartyStrictnessViewControllerDelegate {
    func createPartyStrictnessViewController(partyStrictnessViewController: CreatePartyStrictnessViewController, didSelectStrictness selectedStrictness: PartyStrictnessOption) {
        // Update the strictness and and strictness label, pop the CreatePartyStrictnessViewController
        strictness = selectedStrictness
        strictnessCellStrictnessLabel.text = strictness.PartyStrictnessOptionToString()
        
        if partyAlreadyExists {
            setDoneButtonState()
        }
        
        navigationController!.popViewControllerAnimated(true)
    }
}

extension CreatePartyViewController: UIAlertViewDelegate {
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == 103 {
            if buttonIndex == 1 {
                // If host is leaving the party
                PartyManager.sharedParty.leaveParty(
                    respondToChangeAttempt: { partyWasLeft in
                        if partyWasLeft {
                            self.onSuccessfulPartyCreateOrUpdateOrLeave()
                        } else {
                            let alert = UIAlertView(title: "Could not leave party", message: "Please try again, or just create a new one", delegate: nil, cancelButtonTitle: "Ok")
                            alert.show()
                        }
                    }
                )
            }
        }
    }
}