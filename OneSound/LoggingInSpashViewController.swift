//
//  LoggingInSpashViewController.swift
//  OneSound
//
//  Created by adam on 7/23/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit
import QuartzCore

let LoggingInSpashViewControllerNibName = "LoggingInSpashViewController"
let delayTimeInSeconds = 1.0

var loggingInSpashViewControllerIsShowing = false

class LoggingInSpashViewController: UIViewController {
    
    @IBOutlet weak var splashScreenOneSoundLogo: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removeSplashAfterDelay", name: FinishedLoginFlowNotification, object: nil)
        
        modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController!.setNavigationBarHidden(true, animated: animated)
        activityIndicator.startAnimating()
        
        // Show the side menu so the frame can get set (would otherwise 'slide down' first time being shown)
        // Then hide it
        //let sideMenu = (navigationController as? OSFrontNavigationController)?.sideMenu?
        //sideMenu?.showSideMenu()
        
        super.viewWillAppear(animated)
        loggingInSpashViewControllerIsShowing = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        activityIndicator.stopAnimating()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        loggingInSpashViewControllerIsShowing = false
        AlertManager.sharedManager.onLoggingInSpashViewControllerDidDisappear()
    }
    
    func removeSplashAfterDelay() {
        NSTimer.scheduledTimerWithTimeInterval(delayTimeInSeconds, target: self, selector: "finishedLoginFlow", userInfo: nil, repeats: false)
    }
    
    func finishedLoginFlow() {
        var navC = navigationController as? OSFrontNavigationController
        while navC == nil {
            navC = navigationController as? OSFrontNavigationController
        }
        
        // Setup transition for going to nav controller and execute it by popping this view controller
        let transtion = CATransition()
        transtion.duration = 0.3
        transtion.type = kCATransitionFade
        navC!.view.layer.addAnimation(transtion, forKey: kCATransition)
        navC!.setNavigationBarHidden(false, animated: false)
        navC!.popViewControllerAnimated(false)
        
        if PartyManager.sharedParty.state != .None {
            getAppDelegate().sideMenuViewController.programaticallySelectRow(1)
        }
        
        navC!.setupOverlay()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
