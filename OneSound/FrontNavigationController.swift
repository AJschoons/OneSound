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
    
    var firstTimeAppearing = true
    var overlayHasBeenSet = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationBar.barTintColor = UIColor.white()
        navigationBar.tintColor = UIColor.blue()
        navigationBar.translucent = false
    }
    
    override func viewWillAppear(animated: Bool) {
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