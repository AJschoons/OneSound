//
//  CreatePartyViewController.swift
//  OneSound
//
//  Created by adam on 8/13/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

protocol CreatePartyViewControllerDelegate {
    func CreatePartyViewControllerDone()
}

class CreatePartyViewController: UITableViewController {
        
    let validCharacters = "abcdefghijklmnopqrstuvwxyz1234567890 "
    
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var nameCellTextField: UITextField!
    @IBOutlet weak var nameCellTextFieldCount: UILabel!
    @IBOutlet weak var privacyCell: UITableViewCell!
    var privacyCellSwitch: UISwitch!
    @IBOutlet weak var strictnessCell: UITableViewCell!
    @IBOutlet weak var strictnessCellStrictnessLabel: UILabel!
    
    // TODO: put the party's variables here for when settings are changed
    //var userID: Int!
    //var userAPIToken: String!
    //var userFacebookUID: String!
    //var userFacebookToken: String!
    
    var strictness: PartyStrictnessOption = .Default
    var partyAlreadyExists = false // TODO: figure out if partyAlreadyExists is actually ever used/needed
    
    var delegate: CreatePartyViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup nav bar
        if partyAlreadyExists {
            navigationItem.title = "Change Settings"
        } else {
            navigationItem.title = "Create Party"
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "done")
        navigationItem.rightBarButtonItem!.enabled = false
        
        // Initialize the text field's delegate and character count label
        nameCellTextField.delegate = self
        nameCellTextField.addTarget(self, action: "textFieldDidChange", forControlEvents: UIControlEvents.EditingChanged)
        updateNameCellTextFieldCount()
        
        // TODO: Initialize cells that need to be
        if partyAlreadyExists {
            if let previousStrictness = PartyStrictnessOption(rawValue: LocalParty.sharedParty.strictness) {
                strictness = previousStrictness
            }
        }
        strictnessCellStrictnessLabel.text = strictness.PartyStrictnessOptionToString()
        
        // Give the name text field the party's name if it already exists
        if partyAlreadyExists {
            nameCellTextField.text = LocalParty.sharedParty.name
            updateNameCellTextFieldCount()
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
    }
    
    func cancel() {
        // TODO: see if there's any relevant actions to be taken when the party is cancelled
        /*
        if !accountAlreadyExists {
            LocalUser.sharedUser.setupGuestAccount()
        }
        if delegate != nil {
            delegate!.loginViewControllerCancelled()
        }
        */
        tableView.endEditing(true)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func done() {
        // TODO: find out what the delegate method for "done" should be doing
        
        //dismissViewControllerAnimated(true, completion: nil)
        let partyName = nameCellTextField.text
        
        if !partyAlreadyExists {
            println("Creating NEW party")
            LocalParty.sharedParty.createNewParty(nameCellTextField.text, partyPrivacy: privacyCellSwitch.on, partyStrictness: strictness.rawValue, respondToChangeAttempt: { partyWasCreated in
                    if partyWasCreated {
                        self.tableView.endEditing(true)
                        self.dismissViewControllerAnimated(true, completion: nil)
                        
                        if LocalParty.sharedParty.setup == true {
                            let delegate = UIApplication.sharedApplication().delegate as AppDelegate
                            let snvc = delegate.revealViewController!.rearViewController as SideNavigationViewController
                            snvc.programaticallySelectRow(1)
                        }
                    } else {
                        let alert = UIAlertView(title: "Could not create party", message: "Please try a new name, changing the settings, or restarting the app", delegate: nil, cancelButtonTitle: "Ok")
                        alert.show()
                    }
                }
            )
        } else {
            println("updating party")
            // TODO: updating party code
            
            /*
            var newUserName: String? = nil
            var newUserColor: String? = nil
            if userName != LocalUser.sharedUser.name {
                newUserName = userName
            }
            if userColor != LocalUser.sharedUser.color {
                newUserColor = userColor
            }
            LocalUser.sharedUser.updateServerWithNewNameAndColor(newUserName, color: newUserColor, respondToChangeAttempt:
                { nameIsValid in
                    if nameIsValid {
                        self.tableView.endEditing(true)
                        self.dismissViewControllerAnimated(true, nil)
                    } else {
                        self.notifyThatUserNameIsTaken()
                    }
                }
            )
            */
        }
    }
    
    func textFieldDidChange() {
        updateNameCellTextFieldCount()
        setDoneButtonState()
    }
    
    func setDoneButtonState() {
        if partyAlreadyExists {
            /*
            // Only allow Done to be pressed if party information has changed from what is already is
            if countElements(nameCellTextField.text as String) > 2 && nameCellTextField.text != LocalParty.sharedParty.name || color.OneSoundColorOptionToUserColor().toRaw() != LocalUser.sharedUser.color {
                navigationItem.rightBarButtonItem.enabled = true
            } else {
                navigationItem.rightBarButtonItem.enabled = false
            }
            */
        } else {
            if countElements(nameCellTextField.text as String) > 2 {
                navigationItem.rightBarButtonItem!.enabled = true
            } else {
                navigationItem.rightBarButtonItem!.enabled = false
            }
        }
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