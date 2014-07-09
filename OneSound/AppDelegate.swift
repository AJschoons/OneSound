//
//  AppDelegate.swift
//  OneSound
//
//  Created by adam on 7/7/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

// Set to true to print everything in app to console
var pG = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    var statusBarBackground: UIWindow?
    var viewController: SWRevealViewController?
    var panGestureStartedFrom: UInt32 = 1000000 // 1000000 so it won't init as an enum val
    
    // Set to true to print everything in AppDelegate
    var pL = true

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        // Override point for customization after application launch.
        
        // Make the status bar behave like in iOS6 so it can be hidden but still 
        // retain space above the navigation controller for when side nav is visible
        // See: http://stackoverflow.com/questions/18294872/ios-7-status-bar-back-to-ios-6-default-style-in-iphone-app/18855464#18855464
        // Check if iOS7 or greater
        if (UIDevice.currentDevice().systemVersion as NSString).floatValue >= 7 {
            // Set status bar to be default w/ black icons and text
            application.setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
            
            // Avoid subviews whose frames extend beyond the visible bounds from showing up
            // (for views animating into the main view from top)
            // Commented out because interfered with SideNav
            //window!.clipsToBounds = true
            
            // Create the illusion that the status bar takes up space like how it is in iOS 6 
            // by shifting and resizing the app's window frame
            window!.frame = CGRectMake(0, 20, window!.frame.size.width, window!.frame.size.height - 20)
            
            // Fixes scaling bugs (appearently)
            window!.bounds = CGRectMake(0, 20, window!.frame.size.width, window!.frame.size.height)
            
            // Create a separate status bar background window to edit color
            statusBarBackground = UIWindow(frame: CGRectMake(0, 0, window!.frame.size.width, 20))
            statusBarBackground!.backgroundColor = UIColor.whiteColor()
            statusBarBackground!.hidden = false
            
            // For reacting to screen rotation changes
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidChangeStatusBarOrientation:", name: UIApplicationDidChangeStatusBarOrientationNotification, object: nil)
        }
        
        let frontViewController = FrontViewController()
        let rearViewController = SideNavigationViewController()
        
        let frontNavigationController = FrontNavigationControllerWithoutTabs(rootViewController: frontViewController)
        let rearNavigationController = UINavigationController(rootViewController: rearViewController)
        
        let revealController = SWRevealViewController(rearViewController: rearViewController, frontViewController: frontNavigationController)
        
        revealController.delegate = self
        revealController.rearViewRevealWidth = 200.0
        revealController.rearViewRevealOverdraw = 0.0
        revealController.frontViewShadowOpacity = 0.0
        revealController.bounceBackOnOverdraw = false
        revealController.bounceBackOnLeftOverdraw = false
        revealController.quickFlickVelocity = 1000000 // Disables quick Flicks
        viewController = revealController
        
        window!.rootViewController = viewController
        
        //window!.backgroundColor = UIColor.whiteColor()
        window!.makeKeyAndVisible()
        
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
        
        return true
    }

    func applicationWillResignActive(application: UIApplication!) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication!) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication!) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication!) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication!) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension AppDelegate: SWRevealViewControllerDelegate {
    // MARK: Customizes fading of whatever Front Navigation Controller is conforming to FrontNavigationControllerWithOverlay protocol
    
    func revealController(revealController: SWRevealViewController, animateToPosition position: FrontViewPosition) {
        if position.value == FrontViewPositionRight.value {
            // If will move to show side nav
            printlnC(pL, pG, "animate side nav to VISIBLE")
            
            if let fnc = revealController.frontViewController as? FrontNavigationControllerWithOverlay {
                UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
                UIView.animateWithDuration(revealController.toggleAnimationDuration, animations: {
                    fnc.setOverlayAlpha(0.5)
                    })
            }
        } else if position.value == FrontViewPositionLeft.value {
            // If will move to hide side nav
            printlnC(pL, pG, "animate side nav to HIDDEN")
            if let fnc = revealController.frontViewController as? FrontNavigationControllerWithOverlay {
                UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
                UIView.animateWithDuration(revealController.toggleAnimationDuration, animations: {
                        fnc.setOverlayAlpha(0.0)
                    })
            }
        }
    }
    
    func revealController(revealController: SWRevealViewController, panGestureMovedToLocation location: CGFloat, progress: CGFloat) {
        if let fnc = revealController.frontViewController as? FrontNavigationControllerWithOverlay {
            UIView.animateWithDuration(0.03, animations: {
                fnc.setOverlayAlpha(customCurveEaseInOut(progress) / 2.0)
                })
        }
    }
    
    func revealController(revealController: SWRevealViewController, panGestureBeganFromLocation location: CGFloat, progress: CGFloat) {
        if location < revealController.rearViewRevealWidth / 2.0 {
            // If pan began with side nav hidden, set the most recent pan start to FrontViewPositionLeft
            printlnC(pL, pG, "pan began with side nav HIDDEN")
            panGestureStartedFrom = FrontViewPositionLeft.value
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
        } else if location >= revealController.rearViewRevealWidth / 2.0 {
            // If pan began with side nav visible, set the most recent pan start to FrontViewPositionRight
            printlnC(pL, pG, "pan began with side nav VISIBLE")
            panGestureStartedFrom = FrontViewPositionRight.value
        }
    }
    
    func revealController(revealController: SWRevealViewController, panGestureEndedToLocation location: CGFloat, progress: CGFloat) {
        // Seems that this is the val SFReveal uses to decide where a paritally moved pan should go
        let criticalWidthDenom = 2.0
        
        if panGestureStartedFrom == FrontViewPositionLeft.value {
            // If pan started with side nav HIDDEN
            printlnC(pL, pG, "pan ended after starting with side nav HIDDEN")
            if location >= revealController.rearViewRevealWidth / criticalWidthDenom {
                // If pan ended to the right of critical width point, make side nav VISIBLE
                printlnC(pL, pG, "    pan ended over 1/\(criticalWidthDenom) of the way to side nav VISIBLE, animate side nav to VISIBLE")
                revealController.setFrontViewPosition(FrontViewPositionRight, animated: true)
            } else {
                // If pan ended to the left of critical width point, make side nav HIDDEN
                printlnC(pL, pG, "    pan didn't reach 1/\(criticalWidthDenom) of the way to side nav VISIBLE, animate side nav to HIDDEN")
                revealController.setFrontViewPosition(FrontViewPositionLeft, animated: true)
            }
        } else if panGestureStartedFrom == FrontViewPositionRight.value {
            // If pan started with side nav VISIBLE
            printlnC(pL, pG, "pan ended after starting with side nav VISIBLE")
            if location <= (revealController.rearViewRevealWidth - (revealController.rearViewRevealWidth / criticalWidthDenom)) {
                // If pan ended to the left of critical width point, make side nav HIDDEN
                printlnC(pL, pG, "    pan ended over 1/\(criticalWidthDenom) of the way to side nav HIDDEN, animate side nav to HIDDEN")
                revealController.setFrontViewPosition(FrontViewPositionLeft, animated: true)
            } else {
                // If pan ended to the right of critical width point, make side nav VISIBLE
                printlnC(pL, pG, "    pan didn't reach 1/\(criticalWidthDenom) of the way to side nav HIDDEN, animate side nav to VISIBLE")
                revealController.setFrontViewPosition(FrontViewPositionRight, animated: true)
            }
        }
    }
}

extension AppDelegate {
    // MARK: Responding to status bar changing because of screen orientation
    
    
}