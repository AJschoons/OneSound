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

class LoggingInSpashViewController: UIViewController {
    
    @IBOutlet weak var animatedOneSoundOne: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removeSplashAfterDelay", name: FinishedLoginFlowNotification, object: nil)
        
        let OSLogo0 = UIImage(named: "splashScreenOneSoundOne0")
        let OSLogo1 = UIImage(named: "splashScreenOneSoundOne1")
        let OSLogo2 = UIImage(named: "splashScreenOneSoundOne2")
        
        animatedOneSoundOne!.animationImages = [OSLogo2!, OSLogo1!, OSLogo0!, OSLogo1!]
        animatedOneSoundOne!.animationDuration = 1.5
        // This would be set to stop it from looping forever
        // animatedOneSoundOne!.animationRepeatCount = X
        
        modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController!.setNavigationBarHidden(true, animated: animated)
        animatedOneSoundOne!.startAnimating()
        
        // Show the side menu so the frame can get set (would otherwise 'slide down' first time being shown)
        // Then hide it
        //let sideMenu = (navigationController as? OSFrontNavigationController)?.sideMenu?
        //sideMenu?.showSideMenu()
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        animatedOneSoundOne!.stopAnimating()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func removeSplashAfterDelay() {
        NSTimer.scheduledTimerWithTimeInterval(delayTimeInSeconds, target: self, selector: "finishedLoginFlow", userInfo: nil, repeats: false)
    }
    
    func finishedLoginFlow() {
        let navC = navigationController as OSFrontNavigationController
        
        // Setup transition for going to nav controller and execute it by popping this view controller
        let transtion = CATransition()
        transtion.duration = 0.3
        transtion.type = kCATransitionFade
        navC.view.layer.addAnimation(transtion, forKey: kCATransition)
        navC.setNavigationBarHidden(false, animated: false)
        navC.popViewControllerAnimated(false)
        
        if PartyManager.sharedParty.setup == true {
            getAppDelegate().sideMenuViewController.programaticallySelectRow(1)
        }
        
        navC.setupOverlay()
        
        let alert = UIAlertView(title: "Welcome to party, bitches", message: "You're one of the lucky first 20 people to use OneSound, the app where everyone is the DJ. If you haven't already, sign in with Facebook below, and then go to the 'Party Search' tab, search 'New Years,' and join. This pre-release version expires in 30 days. Hope it treats you well, and Happy New Years!", delegate: nil, cancelButtonTitle: "Gotcha, now let's turn up!")
        alert.show()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
