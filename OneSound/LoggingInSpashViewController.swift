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
        
        animatedOneSoundOne!.animationImages = [OSLogo2, OSLogo1, OSLogo0, OSLogo1]
        animatedOneSoundOne!.animationDuration = 1.5
        // This would be set to stop it from looping forever
        // animatedOneSoundOne!.animationRepeatCount = X
        
        modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController!.setNavigationBarHidden(true, animated: animated)
        animatedOneSoundOne!.startAnimating()
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
        let navC = navigationController as FrontNavigationController
        
        // Setup transition for going to nav controller and execute it by popping this view controller
        let transtion = CATransition()
        transtion.duration = 0.3
        transtion.type = kCATransitionFade
        navC.view.layer.addAnimation(transtion, forKey: kCATransition)
        navC.setNavigationBarHidden(false, animated: false)
        navC.popViewControllerAnimated(false)
        
        if LocalParty.sharedParty.setup == true {
            let delegate = UIApplication.sharedApplication().delegate as AppDelegate
            let snvc = delegate.revealViewController!.rearViewController as SideNavigationViewController
            snvc.programaticallySelectRow(1)
        }
        
        // Add the overlay to the frontNavController that's used with the side menu
        navC.overlay.frame = CGRectMake(0, 20, UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.height - 20)
        navC.overlay.backgroundColor = UIColor.blackColor()
        navC.overlay.alpha = 0.0
        navC.view.addSubview(navC.overlay)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
