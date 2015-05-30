//
//  LoginViewController.swift
//  OneSound
//
//  Created by adam on 7/16/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let LoginViewControllerIdentifier = "LoginViewController"
let LoginStoryboardName = "Login"

protocol LoginViewControllerDelegate {
    func loginViewControllerCancelled()
}

class LoginViewController: OSTableViewController {
    
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var nameCellTextField: UITextField!
    @IBOutlet weak var nameCellTextFieldCount: UILabel!
    @IBOutlet weak var colorCell: UITableViewCell!
    @IBOutlet weak var colorCellColorLabel: UILabel!
    @IBOutlet weak var nameAlreadyTakenLabel: UILabel!
    
    var userID: Int!
    var userAPIToken: String!
    var userFacebookToken: String!
    
    var color: OneSoundColorOption = OneSoundColorOption.Random
    var accountAlreadyExists = false
    
    var delegate: LoginViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        osvcVariables.screenName = LoginViewControllerIdentifier
        
        // Setup nav bar
        if accountAlreadyExists {
            navigationItem.title = "Account Settings"
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "cancel")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Update", style: UIBarButtonItemStyle.Done, target: self, action: "done")
        } else {
            navigationItem.title = "Create Account"
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
        
        // Initialize color label to the initial color
        if accountAlreadyExists {
            color = UserColors(rawValue: UserManager.sharedUser.color)!.UserColorsToOneSoundColorOption()
            colorCellColorLabel.text = color.rawValue
        } else {
            colorCellColorLabel.text = color.rawValue
        }
        
        // Give the name text field the accounts name if it already exists
        if accountAlreadyExists {
            nameCellTextField.text = UserManager.sharedUser.name
            updateNameCellTextFieldCount()
        }
        
        // Initialize the name already taken label to invisible
        nameAlreadyTakenLabel.alpha = 0.0
        
        // Add tap gesture recognizer to dismiss keyboard when background touched
        // Make sure the tap doesn't interfere with touches in the table view
        let tap = UITapGestureRecognizer(target: self, action: "tap")
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
    }
    
    func cancel() {
        if !accountAlreadyExists {
            FBSession.activeSession().closeAndClearTokenInformation()
            UserManager.sharedUser.setupGuestAccount()
        }
        
        if delegate != nil {
            delegate!.loginViewControllerCancelled()
        }
        
        tableView.endEditing(true)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func done() {
        //dismissViewControllerAnimated(true, completion: nil)
        let userColor = color.OneSoundColorOptionToUserColor().rawValue
        let userName = nameCellTextField.text
        
        if !accountAlreadyExists {
            // println("Creating FULL account")
            
            UserManager.sharedUser.setupFullAccount(userName, userColor: userColor, userID: userID, userAccessToken: userAPIToken, providerToken: userFacebookToken,
                respondToChangeAttempt: { nameIsValid in
                    if nameIsValid {
                        self.tableView.endEditing(true)
                        self.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        self.notifyThatUserNameIsTaken()
                    }
                }
            )
        } else {
            var newUserName: String? = nil
            var newUserColor: String? = nil
            if userName != UserManager.sharedUser.name {
                newUserName = userName
            }
            if userColor != UserManager.sharedUser.color {
                newUserColor = userColor
            }
            UserManager.sharedUser.updateUserInformationOnServer(newUserName, color: newUserColor, 
                respondToChangeAttempt: { nameIsValid in
                    if nameIsValid {
                        self.tableView.endEditing(true)
                        self.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        self.notifyThatUserNameIsTaken()
                    }
                }
            )
        }
    }
    
    func setDoneButtonState() {
        if accountAlreadyExists {
            // Only allow Done to be pressed if user information has changed from what is already is
            if count(nameCellTextField.text as String) > 2 && userInfoHasChanged() {
                navigationItem.rightBarButtonItem!.enabled = true
            } else {
                navigationItem.rightBarButtonItem!.enabled = false
            }
        } else {
            if count(nameCellTextField.text as String) > 2 {
                navigationItem.rightBarButtonItem!.enabled = true
            } else {
                navigationItem.rightBarButtonItem!.enabled = false
            }
        }
    }
    
    func userInfoHasChanged() -> Bool {
        let user = UserManager.sharedUser
        return nameCellTextField.text != user.name || color.OneSoundColorOptionToUserColor().rawValue != user.color
    }
    
    func updateNameCellTextFieldCount() {
        let numberOfCharacters = count(nameCellTextField.text as String)
        
        // Update label
        nameCellTextFieldCount.text = "\(numberOfCharacters)/15"
        
        // Change color based on number of characters
        switch numberOfCharacters {
        case 0...2:
            nameCellTextFieldCount.textColor = UIColor.red()
        case 3...10:
            nameCellTextFieldCount.textColor = UIColor.green()
        case 11...13:
            nameCellTextFieldCount.textColor = UIColor.orange()
        case 14...15:
            nameCellTextFieldCount.textColor = UIColor.red()
        default:
            nameCellTextFieldCount.textColor = UIColor.black()
        }
    }
    
    func notifyThatUserNameIsTaken() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut,
            animations: {
                self.nameAlreadyTakenLabel.alpha = 1.0
                self.nameCellTextField.alpha = 0.0
                self.nameCellTextFieldCount.alpha = 0.0
            }, completion: { boolValue in
                UIView.animateWithDuration(0.2, delay: 0.4, options: UIViewAnimationOptions.CurveEaseInOut,
                    animations: {
                        self.nameAlreadyTakenLabel.alpha = 0.0
                        self.nameCellTextField.alpha = 1.0
                        self.nameCellTextFieldCount.alpha = 1.0
                    }, completion: nil
                )
            }
        )
    }
    
    func tap() {
        // Dismiss the keyboard whenever the background is touched while editing
        tableView.endEditing(true)
    }
}

extension LoginViewController: UITableViewDataSource {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return nameCell
        case 1:
            return colorCell
        default:
            // println("Error: LoginViewController cellForRowAtIndexPath couldn't get cell")
            return UITableViewCell()
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
}

extension LoginViewController: UITableViewDelegate {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            // Selecting anywhere in the first cell will start editing text field
            // Otherwise would be weird b/c must touch UITextField but design makes it look otherwise
            nameCellTextField.becomeFirstResponder()
        case 1:
            let loginColorViewController = LoginColorViewController(style: .Plain)
            loginColorViewController.delegate = self
            loginColorViewController.selectedColor = color
            navigationController!.pushViewController(loginColorViewController, animated: true)
        default:
            return
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // Returns false if any of the replacementString characters are invalid
        for c in string {
            if !validCharacters.hasSubstringCaseInsensitive(String(c)) {
                return false
            }
        }
        
        if addingOnlyWhitespaceToTextFieldWithOnlyWhitespaceOrEmpty(textField.text, string) {
            return false
        }
    
        // Only allow change if 15 or less characters
        let newLength = count(textField.text as String) + count(string as String) - range.length
        return ((newLength > 15) ? false : true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide keyboard when user presses "Done"
        removeLeadingWhitespaceFromTextField(&nameCellTextField!)
        nameCellTextField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChange() {
        updateNameCellTextFieldCount()
        setDoneButtonState()
        let numberOfCharacters = count(nameCellTextField.text as String)
        if numberOfCharacters >= 3 {
            let userName = nameCellTextField.text
        OSAPI.sharedClient.GETUserNameValidate(userName,
            success: {data, responseObject in
                let responseJSON = JSON(responseObject)
                //println(responseJSON)
                if let isUserNameValid = responseJSON["valid"].bool {
                    if !isUserNameValid && (UserManager.sharedUser.name != userName){ //username is taken, display red text
                        self.nameCellTextField.textColor = UIColor.red()
                    } else {
                        self.nameCellTextField.textColor = UIColor.black()
                    }
                    
                }
            },
            failure: { task, error in
                defaultAFHTTPFailureBlock!(task: task, error: error)
            }
        )
        }
    }
}

extension LoginViewController: LoginColorViewControllerDelegate {
    func loginColorViewController(loginColorviewController: LoginColorViewController, didSelectColor selectedColor: OneSoundColorOption) {
        // Update color and color label, pop the LoginColorViewController
        color = selectedColor
        colorCellColorLabel.text = color.rawValue
        
        if accountAlreadyExists {
            setDoneButtonState()
        }
        
        navigationController!.popViewControllerAnimated(true)
    }
}