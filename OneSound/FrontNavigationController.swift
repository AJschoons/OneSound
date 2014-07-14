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
    var pL = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        overlay.frame = CGRectMake(0, 20, UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.height - 20)
        overlay.backgroundColor = UIColor.blackColor()
        overlay.alpha = 0.0
        view.addSubview(overlay)
        
        navigationBar.barTintColor = UIColor.white()
        navigationBar.tintColor = UIColor.blue()
        navigationBar.translucent = false
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