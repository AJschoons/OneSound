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
    
    @IBOutlet weak var partySearchBar: UISearchBar!
    @IBOutlet weak var searchResultsTable: UITableView!
    @IBOutlet weak var animatedOneSoundOne: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var createPartyButton: UIBarButtonItem!
    var searchResultsArray = [Party]()
    let heightForRows: CGFloat = 64.0
    let partySearchBarPlaceholderText = "Enter a party name"
    let maxSearchLength = 25
    
    var noSearchResults = false
    
    func search() {
        // Empty the table, reload to show its empty, start the animation
        noSearchResults = false
        searchResultsArray = []
        searchResultsTable.reloadData()
        loadingAnimationShouldBeAnimating(true)
        
        let searchStr = partySearchBar.text
        
        OSAPI.sharedClient.GETPartySearch(searchStr,
            success: {data, responseObject in
                let responseJSON = JSON(responseObject)
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
        if UserManager.sharedUser.guest == false {
            let createPartyStoryboard = UIStoryboard(name: CreatePartyStoryboardName, bundle: nil)
            let createPartyViewController = createPartyStoryboard.instantiateViewControllerWithIdentifier(CreatePartyViewControllerIdentifier) as! CreatePartyViewController
            createPartyViewController.partyAlreadyExists = false
            // TODO: create the delegate methods and see what they mean
            //createPartyViewController.delegate = self
            let navC = UINavigationController(rootViewController: createPartyViewController)
            
            getFrontNavigationController()?.presentViewController(navC, animated: true, completion: nil)
        } else {
            let alert = UIAlertView(title: "Guests cannot create parties", message: "Please become a full account by logging in with Facebook, then try again", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
            alert.show()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Party Search"
        
        let fnc = getFrontNavigationController()
        let sideMenuButtonItem = UIBarButtonItem(image: UIImage(named: "sideMenuToggleIcon"), style: UIBarButtonItemStyle.Plain, target: fnc, action: "toggleSideMenu")
        navigationItem.leftBarButtonItem = sideMenuButtonItem
        
        // Stop view from being covered by the nav bar / laid out from top of screen
        edgesForExtendedLayout = UIRectEdge.None
        
        createPartyButton = UIBarButtonItem(title: "Create", style: UIBarButtonItemStyle.Plain, target: self, action: "createParty")
        navigationItem.rightBarButtonItem = createPartyButton
        
        // Set the table cells to use
        let nib = UINib(nibName: PartySearchResultCellNibName, bundle: nil)
        searchResultsTable.registerNib(nib, forCellReuseIdentifier: PartySearchResultCellIdentifier)
        // Creating an (empty) footer stops table from showing empty cells
        searchResultsTable.tableFooterView = UIView(frame: CGRectZero)
        
        // Setup the search bar
        partySearchBar.delegate = self
        partySearchBar.enablesReturnKeyAutomatically = true
        partySearchBar.layer.borderWidth = 1
        partySearchBar.layer.borderColor = UIColor.grayLight().CGColor
        
        let tap = UITapGestureRecognizer(target: self, action: "tap")
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Setup loading animation
        //animatedOneSoundOne.animationImages = [loadingOSLogo2, loadingOSLogo1, loadingOSLogo0, loadingOSLogo1]
        //animatedOneSoundOne.animationDuration = 1.5
        //animatedOneSoundOne.hidden = true
        activityIndicator.hidden = true
        
        // Make view respond to network reachability changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
        // Make sure view knows the user is setup so it won't keep displaying 'Not signed into account' when there is no  internet connection when app launches and then the network comes back and UserManager is setup
        // Also will refresh the "Create" button
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: UserManagerInformationDidChangeNotification, object: nil)
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
        // if count(partySearchTextField.text as String) > 2 {
    }
    
    func tap() {
        // Dismiss the keyboard whenever the background is touched while editing
        view.endEditing(true)
    }
    
    func loadingAnimationShouldBeAnimating(animating: Bool) {
        if animating {
            //animatedOneSoundOne.hidden = false
            //animatedOneSoundOne.startAnimating()
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
        } else {
            //animatedOneSoundOne.hidden = true
            //animatedOneSoundOne.stopAnimating()
            activityIndicator.hidden = true
            activityIndicator.stopAnimating()
        }
    }
    
    func refresh() {
        println("refreshing PartyMembersViewController")
        
        if AFNetworkReachabilityManager.sharedManager().reachable {
            if UserManager.sharedUser.setup == true {
                hideMessages()
                
                if UserManager.sharedUser.guest == true {
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
        partySearchBar.hidden = hidden
        searchResultsTable.hidden = hidden
        
        if (hidden)
        {
            //animatedOneSoundOne.hidden = hidden
            activityIndicator.hidden = hidden
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
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultsArray.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if !noSearchResults {
            tableView.backgroundView = nil
            return 1
        } else {
            // Display a message when the table is empty after searching
            setTableBackgroundViewWithMessages(tableView, "No parties found", "Please try searching with a different name")
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = searchResultsTable.dequeueReusableCellWithIdentifier(PartySearchResultCellIdentifier, forIndexPath: indexPath) as! PartySearchResultCell
        
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
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedParty = searchResultsArray[indexPath.row]
        
        if UserManager.sharedUser.setup == true {
            PartyManager.sharedParty.joinParty(selectedParty.partyID,
                JSONUpdateCompletion: {
                    PartyManager.sharedParty.refresh(completion: {
                        if PartyManager.sharedParty.state != .None {
                            // Navigate to the party
                            getAppDelegate()!.sideMenuViewController.programaticallySelectRow(1)
                        } else {
                            let alert = UIAlertView(title: "Problem Joining Party", message: "Unable to join party at this time, please try again", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                            alert.show()
                        }
                        
                        self.searchResultsArray = [Party]() // Remove the results so they have to search again
                        tableView.reloadData()
                    })
                    
                    if PartyManager.sharedParty.state != .None {
                        getAppDelegate()!.sideMenuViewController.programaticallySelectRow(1)
                    }
                }, failureAddOn: {
                    PartyManager.sharedParty.refresh()
                    self.searchResultsArray = [] // Remove the results so they have to search again
                    tableView.reloadData()
                    let alert = UIAlertView(title: "Problem Joining Party", message: "Unable to join party at this time, please try again", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                    alert.show()
                }
            )
        } else {
            let alert = UIAlertView(title: "Not Signed In", message: "Please sign into an account before joining a party", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
            alert.show()
        }
        
        // Deselect it after
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return heightForRows
    }
}

extension SearchViewController: UIScrollViewDelegate {
    // MARK: UIScrollViewDelegate
    
    // Dismisses the keyboard when the user was editing text after searching, then looks at results again
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        partySearchBar.resignFirstResponder()
    }
}

extension SearchViewController: UISearchBarDelegate {
    // MARK: UISearchBarDelegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        // TODO: search while typing
        
        // Clear search data (this should happen when user presses the 'x' on the right side)
        if count(searchText) == 0 {
            noSearchResults = false
            searchResultsArray = []
            searchResultsTable.reloadData()
        }
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.placeholder = nil
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.placeholder = partySearchBarPlaceholderText
    }
    
    // Hide keyboard when user presses "Search", initiate the search
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        removeLeadingWhitespaceFromSearchBar(&partySearchBar!)
        partySearchBar.resignFirstResponder()
        search()
    }
    
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        // Returns false if any of the replacementString characters are invalid
        for c in text {
            if c != " " && c != "\n" && !validCharacters.hasSubstringCaseInsensitive(String(c)) {
                return false
            }
        }
        
        if addingOnlyWhitespaceToTextFieldWithOnlyWhitespaceOrEmpty(searchBar.text, text) {
            return false
        }
        
        // Only allow change if 25 or less characters
        let newLength = count(searchBar.text as String) + count(text as String) - range.length
        return newLength <= maxSearchLength
    }
}

extension SearchViewController: SideMenuNavigableViewControllerWithKeyboard {
    func hideKeyboard() {
        partySearchBar.resignFirstResponder()
    }
}

