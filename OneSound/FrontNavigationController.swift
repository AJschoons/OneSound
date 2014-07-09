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

class FrontNavigationControllerWithoutTabs: UINavigationController {
    
    let overlay = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        overlay.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
        overlay.backgroundColor = UIColor.blackColor()
        overlay.alpha = 0.0
        view.addSubview(overlay)
    }
}

extension FrontNavigationControllerWithoutTabs: FrontNavigationControllerWithOverlay {
    
    func setOverlayAlpha(newAlpha: CGFloat) {
        overlay.alpha = newAlpha
    }
}
