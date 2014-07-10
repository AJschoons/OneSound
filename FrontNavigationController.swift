//
//  FrontNavigationController.swift
//  OneSound
//
//  Created by adam on 7/9/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

@objc protocol FrontNavigationControllerWithOverlay {
    
    func setOverlayAlpha(CGFloat)
}



class FrontNavigationController: UINavigationController {
    
    var overlay = UIView()
    var pL = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Make it 20 px smaller to account for status bar
        //view.frame = CGRectMake(0, 20, view.frame.width, view.frame.height - 20.0)
        
        overlay.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.height)
        overlay.backgroundColor = UIColor.blackColor()
        overlay.alpha = 0.0
        view.addSubview(overlay)
        
        navigationBar.barTintColor = UIColor.whiteColor()
        navigationBar.translucent = false
    }
    
    override func viewDidAppear(animated: Bool) {
        printlnC(pL, pG, "viewDidAppear frame of front nav:\(view.frame) bounds:\(view.bounds)")
        
        
    }
}

extension FrontNavigationController: FrontNavigationControllerWithOverlay {
    
    func setOverlayAlpha(newAlpha: CGFloat) {
        overlay.alpha = newAlpha
    }
}

extension FrontNavigationController: UIBarPositioningDelegate {
    func positionForBar(bar: UIBarPositioning!) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}