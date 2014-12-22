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
    
    var noSearchResults = false
    
    func search() {
        // Empty the table, reload to show its empty, start the animation
        noSearchResults = false
        searchResultsArray = []
        searchResultsTable.reloadData()
        loadingAnimationShouldBeAnimating(true)
        
        let searchStr = partySearchTextField.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        OSAPI.sharedClient.GETPartySearch(searchStr,
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
                
                if partiesArray!.count == 0 { self.noSearchResults = true }
                
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
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and LocalUser is setup
        // Also will refresh the "Create" button
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: LocalUserInformationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // Remove the results so they have to search again and keep the info fresh when they come back
        noSearchResults = false
        searchResultsArray = []
        searchResultsTable.reloadData()
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
                
                setViewInfoHidden(false)
                
            } else {
                setViewInfoHidden(true)
                showMessages("Not signed into an account", detailLine: "Please connect to the internet and restart OneSound")
                disableButtons()
                searchResultsArray = []
                searchResultsTable.reloadData()
            }
        } else {
            setViewInfoHidden(true)
            showMessages("Not connected to the internet", detailLine: "Please connect to the internet to use OneSound")
            disableButtons()
            searchResultsArray = []
            searchResultsTable.reloadData()
        }
    }
    
    func setViewInfoHidden(hidden: Bool) {
        partySearchTextField.hidden = hidden
        searchResultsTable.hidden = hidden
        
        if (hidden)
        {
            animatedOneSoundOne.hidden = hidden
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
        return noSearchResults ? 1 : searchResultsArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = searchResultsTable.dequeueReusableCellWithIdentifier(PartySearchResultCellIdentifier, forIndexPath: indexPath) as PartySearchResultCell
        
        if noSearchResults {
            cell.nameLabel.text = "No Parties Found"
            cell.userNameLabel.text = "Check spelling and try searching again"
            cell.memberCountLabel.text = ""
        } else {
            let result = searchResultsArray[indexPath.row]
            
            var nameText: String = (result.name != nil) ? result.name! : ""
            var userText: String = (result.hostName != nil) ? "Created by \(result.hostName!)" : "Created by Host"
            var membersText: String = (result.memberCount != nil) ? "\(thousandsFormatter.stringFromNumber(NSNumber(integer: result.memberCount!))!) members" : "0 members"
            
            cell.nameLabel.text = nameText
            cell.userNameLabel.text = userText
            cell.memberCountLabel.text = membersText
        }

        return cell
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        if noSearchResults { return }
        
        let selectedParty = searchResultsArray[indexPath.row]
        
        if LocalUser.sharedUser.setup == true {
            LocalParty.sharedParty.joinParty(selectedParty.partyID,
                JSONUpdateCompletion: {
                    LocalParty.sharedParty.refresh()
                    self.searchResultsArray = [Party]() // Remove the results so they have to search again
                    
                    if LocalParty.sharedParty.setup == true {
                        let delegate = UIApplication.sharedApplication().delegate as AppDelegate
                        let snvc = delegate.revealViewController!.rearViewController as SideNavigationViewController
                        snvc.programaticallySelectRow(1)
                    }
                }, failureAddOn: {
                    LocalParty.sharedParty.refresh()
                    self.searchResultsArray = [] // Remove the results so they have to search again
                    tableView.reloadData()
                    let alert = UIAlertView(title: "Problem Joining Party", message: "Unable to join party at this time, please try again", delegate: nil, cancelButtonTitle: "Ok")
                    alert.show()
                }
            )
        } else {
            let alert = UIAlertView(title: "Not Signed In", message: "Please sign into an account before joining a party", delegate: nil, cancelButtonTitle: "Ok")
            alert.show()
        }
        
        // Deselect it after
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return heightForRows
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return !noSearchResults
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



