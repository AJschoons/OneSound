//
//  LoggingInSpashViewController.swift
//  OneSound
//
//  Created by adam on 7/23/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class LoggingInSpashViewController: UIViewController {
    
    @IBOutlet weak var animatedOneSoundOne: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishedLoginFlow", name: FinishedLoginFlowNotification, object: nil)
        
        let OSLogo0 = UIImage(named: "splashScreenOneSoundOne0")
        let OSLogo1 = UIImage(named: "splashScreenOneSoundOne1")
        let OSLogo2 = UIImage(named: "splashScreenOneSoundOne2")
        
        animatedOneSoundOne!.animationImages = [OSLogo2, OSLogo1, OSLogo0, OSLogo1]
        animatedOneSoundOne!.animationDuration = 1.5
        // This would be set to stop it from looping forever
        // animatedOneSoundOne!.animationRepeatCount = X
        
        modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        animatedOneSoundOne!.startAnimating()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        animatedOneSoundOne!.stopAnimating()
    }
    
    func finishedLoginFlow() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
