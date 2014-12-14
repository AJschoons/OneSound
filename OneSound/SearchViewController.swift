//
//  SearchViewController.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

let SearchViewControllerNibName = "SearchViewController"
let PartySearchResultCellIdentifier = "PartySearchResultCell"

class SearchViewController: UIViewController {
    
    @IBOutlet weak var messageLabel1: UILabel?
    @IBOutlet weak var messageLabel2: UILabel?
    @IBOutlet weak var partySearchTextField: UITextField!

    @IBOutlet weak var searchResultsTable: UITableView!
    
    @IBOutlet weak var animatedOneSoundOne: UIImageView!
    
    var createPartyButton: UIBarButtonItem!
    var searchResultsArray = [Party]()
    let heightForRows: CGFloat = 64.0
    
    func search() {
        // Empty the table, reload to show its empty, start the animation
        searchResultsArray = [Party]()
        searchResultsTable.reloadData()
        loadingAnimationShouldBeAnimating(true)
        
        OSAPI.sharedClient.GETPartySearch(partySearchTextField.text,
            success: {data, responseObject in
                let responseJSON = JSONValue(responseObject)
                println(responseJSON)
                let partiesArray = responseJSON.array
                println(partiesArray!)
                println(partiesArray!.count)
                
                // Get the parties in the results and store them
                var newPartySearchResults = [Party]()
                if partiesArray != nil {
                    for result in partiesArray! {
                        //println(result)
                        newPartySearchResults.append(Party(json: result))
                    }
                }
                
                // Update the party results, reload the table to show them, stop animating
                self.searchResultsArray = newPartySearchResults
                self.searchResultsTable.reloadData()
                self.loadingAnimationShouldBeAnimating(false)
            },
            failure: { task, error in
                self.loadingAnimationShouldBeAnimating(false)
                defaultAFHTTPFailureBlock!(task: task, error: error)
            }
        )
    }
    
    func createParty() {
        if LocalUser.sharedUser.guest == false {
            let createPartyStoryboard = UIStoryboard(name: "CreateParty", bundle: nil)
            let createPartyViewController = createPartyStoryboard.instantiateViewControllerWithIdentifier("CreatePartyViewController") as CreatePartyViewController
            createPartyViewController.partyAlreadyExists = false
            // TODO: create the delegate methods and see what they mean
            //createPartyViewController.delegate = self
            let navC = UINavigationController(rootViewController: createPartyViewController)
            
            let delegate = UIApplication.sharedApplication().delegate as AppDelegate
            let fvc = delegate.revealViewController!.frontViewController
            fvc.presentViewController(navC, animated: true, completion: nil)
        } else {
            let alert = UIAlertView(title: "Guests cannot create parties", message: "Please become a full account by logging in with Facebook, then try again", delegate: nil, cancelButtonTitle: "Ok")
            alert.show()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Search"
        
        // Setup the revealViewController to work for this view controller,
        // add its sideMenu icon to the nav bar
        let revealController = revealViewController()
        revealController.panGestureRecognizer()
        revealController.tapGestureRecognizer()
        let revealButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: revealController, action: "revealToggle:")
        navigationItem.leftBarButtonItem = revealButtonItem
        
        createPartyButton = UIBarButtonItem(title: "Create", style: UIBarButtonItemStyle.Plain, target: self, action: "createParty")
        navigationItem.rightBarButtonItem = createPartyButton
        
        // Set the table cells to use
        let nib = UINib(nibName: PartySearchResultCellNibName, bundle: nil)
        searchResultsTable.registerNib(nib, forCellReuseIdentifier: PartySearchResultCellIdentifier)
        // Creating an (empty) footer stops table from showing empty cells
        searchResultsTable.tableFooterView = UIView(frame: CGRectZero)
        
        partySearchTextField.delegate = self
        partySearchTextField.enablesReturnKeyAutomatically = true
        partySearchTextField.addTarget(self, action: "textFieldDidChange", forControlEvents: UIControlEvents.EditingChanged)
        
        let tap = UITapGestureRecognizer(target: self, action: "tap")
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Setup loading animation
        animatedOneSoundOne.animationImages = [loadingOSLogo2, loadingOSLogo1, loadingOSLogo0, loadingOSLogo1]
        animatedOneSoundOne.animationDuration = 1.5
        animatedOneSoundOne.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    // The text in the field has changed
    func textFieldDidChange() {
        // Make changes based on the number of characters in the text field
        // TODO: Only allow searching with 3+ characters (not a huge deal)
        // if countElements(partySearchTextField.text as String) > 2 {
    }
    
    func tap() {
        // Dismiss the keyboard whenever the background is touched while editing
        view.endEditing(true)
    }
    
    func loadingAnimationShouldBeAnimating(shouldBeAnimating: Bool) {
        if shouldBeAnimating {
            animatedOneSoundOne.hidden = false
            animatedOneSoundOne.startAnimating()
        } else {
            animatedOneSoundOne.hidden = true
            animatedOneSoundOne.stopAnimating()
        }
    }
    
    // Copy pasta'd from Profile view controller to have the same kind of refresh logic
    // Keeping the commented out things for now to show what kind of changes were made for that
    // TODO: update the refresh to remove comments irrelevant to this controller when finished w/ it
    func refresh() {
        println("refreshing PartyMembersViewController")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if LocalUser.sharedUser.setup == true {
                hideMessages()
                if LocalUser.sharedUser.guest == true {
                    createPartyButton.enabled = false
                } else {
                    createPartyButton.enabled = true
                }
            } else {
                //setUserInfoHidden(true)
                //setStoriesTableToHidden(true)
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart One Sound")
                disableButtons()
            }
        } else {
            //setUserInfoHidden(true)
            //setStoriesTableToHidden(true)
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use One Sound")
            disableButtons()
        }
    }
    
    func showMessages(mainLine: String?, detailLine: String?) {
        if mainLine != nil {
            messageLabel1!.alpha = 1
            messageLabel1!.text = mainLine
        }
        if detailLine != nil {
            messageLabel2!.alpha = 1
            messageLabel2!.text = detailLine
        }
    }
    
    func disableButtons() {
        createPartyButton.enabled = false
    }
    
    func hideMessages() {
        messageLabel1!.alpha = 0
        messageLabel1!.text = ""
        messageLabel2!.alpha = 0
        messageLabel2!.text = ""
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultsArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = searchResultsTable.dequeueReusableCellWithIdentifier(PartySearchResultCellIdentifier, forIndexPath: indexPath) as PartySearchResultCell
        let result = searchResultsArray[indexPath.row]
        
        var nameText: String = (result.name != nil) ? result.name! : ""
        var userText: String = (result.hostName != nil) ? "Created by \(result.hostName!)" : "Created by Host"
        var membersText: String = (result.memberCount != nil) ? "\(thousandsFormatter.stringFromNumber(NSNumber(integer: result.memberCount!))!) members" : "0 members"
        
        cell.nameLabel.text = nameText
        cell.userNameLabel.text = userText
        cell.memberCountLabel.text = membersText

        return cell
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let selectedParty = searchResultsArray[indexPath.row]
        
        if LocalUser.sharedUser.setup == true {
            LocalParty.sharedParty.joinParty(selectedParty.partyID,
                JSONUpdateCompletion: {
                    LocalParty.sharedParty.refresh()
                }, failureAddOn: {
                    self.searchResultsArray = [Party]() // Remove the results so they have to search again
                    
                    LocalParty.sharedParty.refresh()
                    let alert = UIAlertView(title: "Problem Joining Party", message: "Unable to join party at this time, please try again", delegate: nil, cancelButtonTitle: "Ok")
                    alert.show()
                }
            )
            /*
            OSAPI.sharedClient.POSTSong(LocalParty.sharedParty.partyID, externalID: selectedSong.externalID, source: source, title: selectedSong.name, artist: selectedSong.artistName, duration: selectedSong.duration, artworkURL: selectedSong.artworkURL, userID: LocalUser.sharedUser.id, userAPIToken: LocalUser.sharedUser.apiToken,
                success: { data, responseObject in
                    self.dismissViewControllerAnimated(true, completion: nil)
                    NSNotificationCenter.defaultCenter().postNotificationName(PartySongWasAddedNotification, object: nil)
                }, failure: { task, error in
                    self.dismissViewControllerAnimated(true, completion: nil)
                    let alert = UIAlertView(title: "Problem Adding Song", message: "The song could not be added to the playlist, please try a different song", delegate: nil, cancelButtonTitle: "Ok")
                    alert.show()
                }
            )*/
        } else {
            let alert = UIAlertView(title: "Not Signed In", message: "Please sign into an account before joining a party", delegate: nil, cancelButtonTitle: "Ok")
            alert.show()
        }
    }
    
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return heightForRows
    }
}

extension SearchViewController: UITextFieldDelegate {
    func textField(textField: UITextField!, shouldChangeCharactersInRange range: NSRange, replacementString string: String!) -> Bool {
        // Returns false if any of the replacementString characters are invalid
        for c in string {
            if c != " " && !validCharacters.hasSubstringCaseInsensitive(String(c)) {
                return false
            }
        }
        
        if addingOnlyWhitespaceToTextFieldWithOnlyWhitespaceOrEmpty(textField.text, string) {
            return false
        }
        
        // Only allow change if 25 or less characters
        let newLength = countElements(textField.text as String) + countElements(string as String) - range.length
        return ((newLength > 25) ? false : true)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        // Hide keyboard when user presses "Search", initiate the search
        removeLeadingWhitespaceFromTextField(&partySearchTextField!)
        partySearchTextField.resignFirstResponder()
        search()
        return true
    }
}



