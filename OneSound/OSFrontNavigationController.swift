//
//  OSNavigationController.swift
//  OneSound
//
//  Created by adam on 1/2/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

class OSFrontNavigationController: ENSideMenuNavigationController {
    
    var overlay: UIView?
    
    override init(menuTableViewController: UITableViewController, contentViewController: UIViewController?) {
        super.init(menuTableViewController: menuTableViewController, contentViewController: contentViewController)
        
        sideMenu!.delegate = self
        sideMenu!.menuWidth = 160.0
        sideMenu!.bouncingEnabled = false
        
        setupNavigationAndToolbarAppearance()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = UIRectEdge.None
    }
    
    func hideKeyboardOfVisibleViewController() {
        if let vc = visibleViewController as? SideMenuNavigableViewControllerWithKeyboard {
            vc.hideKeyboard()
        }
    }
    
    func setupOverlay() {
        // Add the overlay to the frontNavController that's used with the side menu
        overlay = UIView()
        overlay!.frame = CGRectMake(0, 64, UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.height - 64)
        overlay!.backgroundColor = UIColor.blackColor()
        overlay!.alpha = 0.0
        overlay!.userInteractionEnabled = true
        view.addSubview(overlay!)
        
        // Add left swipe gesture recognizer for closing the menu when open from the overlay
        let leftSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleOverlayLeftSwipe")
        leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Left
        overlay!.addGestureRecognizer(leftSwipeGestureRecognizer)
    }
    
    func toggleSideMenu() {
        sideMenu!.toggleMenu()
    }
    
    func handleOverlayLeftSwipe() {
        if sideMenu!.isMenuOpen { sideMenu!.hideSideMenu() }
    }
    
    func setupNavigationAndToolbarAppearance() {
        navigationBar.setBackgroundImage(UIImage(named: "navigationBarBackground"), forBarMetrics: UIBarMetrics.Default)
        navigationBar.shadowImage = UIImage(named: "navigationBarShadow")
        navigationBar.tintColor = UIColor.blue()
        navigationBar.barTintColor = UIColor.white()
        navigationBar.translucent = true
        
        toolbar.setBackgroundImage(UIImage(named: "toolbarBackground"), forToolbarPosition: UIBarPosition.Bottom, barMetrics: UIBarMetrics.Default)
        toolbar.setShadowImage(UIImage(named: "toolbarShadow"), forToolbarPosition: UIBarPosition.Bottom)
        toolbar.tintColor = UIColor.blue()
        toolbar.barTintColor = UIColor.white()
        toolbar.translucent = true
    }
}

extension OSFrontNavigationController: ENSideMenuDelegate {
    // MARK: - ENSideMenu Delegate
    func sideMenuWillOpen() {
        println("sideMenuWillOpen")
        hideKeyboardOfVisibleViewController()
    }
    
    func sideMenuWillClose() {
        println("sideMenuWillClose")
    }
    
    func getOverlay() -> UIView? {
        return overlay
    }
}

extension FrontNavigationController: UIBarPositioningDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}
