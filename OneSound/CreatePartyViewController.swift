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

class CreatePartyViewController: OSTableViewController {
        
    private let ValidCharacters = "abcdefghijklmnopqrstuvwxyz1234567890 "
    private let MinimumFooterViewHeight: CGFloat = 140
    private let LocationCellFooterHeight: CGFloat = 100
    private let DefaultCellFooterHeight: CGFloat = 45
    
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var nameCellTextField: UITextField!
    @IBOutlet weak var nameCellTextFieldCount: UILabel!
    
    @IBOutlet weak var privacyCell: UITableViewCell!
    private var privacyCellSwitch: UISwitch!
    
    @IBOutlet weak var strictnessCell: UITableViewCell!
    @IBOutlet weak var strictnessCellStrictnessLabel: UILabel!
    
    @IBOutlet weak var locationCell: UITableViewCell!
    @IBOutlet weak var locationCellStatusIcon: UIImageView!
    
    @IBOutlet weak var footerView: UIView!
    
    private var locationCellFooterViewController: LocationCellFooterViewController?
    
    private var streamControlButton: UIButton?
    private let scButtonTitleEnabled = "Control Music Stream"
    private let scButtonTitleDisabled = "Controlling Music Stream"
    private let scButtonTextColorEnabled = UIColor.white()
    private let scButtonTextColorDisabled = UIColor.grayLight()
    private let scButtonBGColorEnabled = UIColor.blue()
    private let scButtonBGColorDisabled = UIColor.grayMid()
    
    private var skipSongButton: UIButton?
    private let skipButtonTitle = "Skip Playing Song"
    private let skipButtonTextColorEnabled = UIColor.white()
    private let skipButtonTextColorDisabled = UIColor.grayLight()
    private let skipButtonBGColorEnabled = UIColor.red()
    private let skipButtonBGColorDisabled = UIColor.grayMid()
    
    private var leavePartyButton: UIButton?
    
    private var strictness: PartyStrictnessOption = .Default
    var partyAlreadyExists = false
    private var location: CLLocation?
    
    var delegate: CreatePartyViewControllerDelegate?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        osvcVariables.screenName = CreatePartyViewControllerIdentifier
        
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
        } else {
            locationCellFooterViewController = LocationCellFooterViewController(nibName: LocationCellFooterViewControllerNibName, bundle: nil)
            locationCellFooterViewController!.delegate = self
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
            // println("Creating NEW party")
            PartyManager.sharedParty.createNewParty(nameCellTextField.text, privacy: privacyCellSwitch.on, strictness: strictness.rawValue, location: location!,
                respondToChangeAttempt: { partyWasCreated in
                    if partyWasCreated {
                        self.onSuccessfulPartyCreateOrUpdateOrLeave()
                    } else {
                        let alert = UIAlertView(title: "Could not create party", message: "Please try a new name, changing the settings, or restarting the app", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                        alert.show()
                    }
                }
            )
        } else {
            // println("updating party information")
            PartyManager.sharedParty.changePartyInfo(nameCellTextField.text, privacy: privacyCellSwitch.on, strictness: strictness.rawValue,
                respondToChangeAttempt: { partyWasUpdated in
                    if partyWasUpdated {
                        self.onSuccessfulPartyCreateOrUpdateOrLeave()
                    } else {
                        let alert = UIAlertView(title: "Could not update party", message: "Please try a new name, changing the settings, or restarting the app", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
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
        alert.tag = AlertTag.LeavingPartyAsHost.rawValue
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
                let alert = UIAlertView(title: "Music Control Failure", message: "Failed to get the music stream control. Please reload the party settings and try again", delegate: self, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.show()
            }
        })
    }
    
    func textFieldDidChange() {
        updateNameCellTextFieldCount()
        setDoneButtonState()
    }
    
    private func setDoneButtonState() {
        if partyAlreadyExists {
            // Only allow Done to be pressed if party information has changed from what is already is
            // TODO: add in a check for privacy info change
            if count(nameCellTextField.text as String) > 2 && partyInfoHasChanged() {
                navigationItem.rightBarButtonItem!.enabled = true
            } else {
                navigationItem.rightBarButtonItem!.enabled = false
            }
        } else {
            if count(nameCellTextField.text as String) > 2 && location != nil {
                navigationItem.rightBarButtonItem!.enabled = true
            } else {
                navigationItem.rightBarButtonItem!.enabled = false
            }
        }
    }
    
    private func partyInfoHasChanged() -> Bool {
        // TODO: add in a check for privacy info change
        let party = PartyManager.sharedParty
        return (nameCellTextField.text != party.name) || (strictness.rawValue != party.strictness)
    }
    
    private func updateNameCellTextFieldCount() {
        let numberOfCharacters = count(nameCellTextField.text as String)
        
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
    
    private func setupButtonsInTableFooterView() {
        tableView.layoutIfNeeded() // Calculates the content size
        var footerViewHeight = UIScreen.mainScreen().bounds.height - NavigationBarHeight - tableView.contentSize.height
        if (footerViewHeight < MinimumFooterViewHeight) { footerViewHeight = MinimumFooterViewHeight }
        
        let footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.width, CGFloat(footerViewHeight)))
        footerView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = footerView
        
        let partyManger = PartyManager.sharedParty
        let userIsHostStreamable = (partyManger.state == .HostStreamable)
        let userIsHost = (partyManger.state == .Host)
        
        let streamControlButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
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
        
        let skipSongButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
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
        
        let leavePartyButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
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
        footerView.addConstraint(NSLayoutConstraint(item: leavePartyButton, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: footerView, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: -10))
    }
}

extension CreatePartyViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return nameCell
        case 1:
            return strictnessCell
        case 2:
            return locationCell
        default:
            // println("Error: LoginViewController cellForRowAtIndexPath couldn't get cell")
            return UITableViewCell()
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return partyAlreadyExists ? 2 : 3
    }
}

extension CreatePartyViewController: UITableViewDelegate {
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            // Selecting anywhere in the first cell will start editing text field
            // Otherwise would be weird b/c must touch UITextField but design makes it look otherwise
            nameCellTextField.becomeFirstResponder()
        case 1:
            let createPartyStrictnessViewController = CreatePartyStrictnessViewController(style: .Plain)
            createPartyStrictnessViewController.delegate = self
            createPartyStrictnessViewController.selectedStrictness = strictness
            navigationController!.pushViewController(createPartyStrictnessViewController, animated: true)
        default:
            return
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Only highlight the party strictness cell
        return indexPath.section == 1
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section != 2 { return nil }
        
        tableView.layoutIfNeeded() // Calculates the content size
        var footerViewHeight = UIScreen.mainScreen().bounds.height - NavigationBarHeight - tableView.contentSize.height
        
        let footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.width, 200))
        footerView.backgroundColor = UIColor.purple()
        
        return locationCellFooterViewController?.view
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 2 && !partyAlreadyExists {
            return LocationCellFooterHeight
        } else {
            return DefaultCellFooterHeight
        }
    }
}

extension CreatePartyViewController: UITextFieldDelegate {
    // MARK: UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // Returns false if any of the replacementString characters are invalid
        for c in string {
            if !ValidCharacters.hasSubstringCaseInsensitive(String(c)) {
                return false
            }
        }
        
        if addingOnlyWhitespaceToTextFieldWithOnlyWhitespaceOrEmpty(textField.text, string) {
            return false
        }
        
        // Only allow change if 20 or less characters
        let newLength = count(textField.text as String) + count(string as String) - range.length
        return ((newLength > 20) ? false : true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide keyboard when user presses "Done"
        removeLeadingWhitespaceFromTextField(&nameCellTextField!)
        nameCellTextField.resignFirstResponder()
        return true
    }
}

extension CreatePartyViewController: CreatePartyStrictnessViewControllerDelegate {
    // MARK: CreatePartyStrictnessViewControllerDelegate
    
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
    // MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == AlertTag.LeavingPartyAsHost.rawValue {
            if buttonIndex == 1 {
                // If host is leaving the party
                PartyManager.sharedParty.leaveParty(
                    respondToChangeAttempt: { partyWasLeft in
                        if partyWasLeft {
                            self.onSuccessfulPartyCreateOrUpdateOrLeave()
                        } else {
                            let alert = UIAlertView(title: "Could not leave party", message: "Please try again, or just create a new one", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                            alert.show()
                        }
                    }
                )
            }
        }
    }
}

extension CreatePartyViewController: LocationCellFooterDelegate {
    // MARK: LocationCellFooterDelegate
    
    func receivedLocation(location: CLLocation) {
        self.location = location
        //let lat = location.coordinate.latitude
        //let long = location.coordinate.longitude
        locationCellStatusIcon.image = UIImage(named: "checkIcon")
        setDoneButtonState()
    }
}