//
//  AppDelegate.swift
//  OneSound
//
//  Created by adam on 7/7/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit
import QuartzCore

// Set to true to print everything in app to console
var pG = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    //var statusBarBackground: UIWindow?
    var revealViewController: SWRevealViewController?
    var panGestureStartedFrom: UInt32 = 1000000 // 1000000 so it won't init as an enum val
    
    // Set to true to print everything in AppDelegate
    var pL = false

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        // Override point for customization after application launch.
        
        let frontViewController = FrontViewController()
        let rearViewController = SideNavigationViewController()
        
        let frontNavigationController = FrontNavigationController(rootViewController: frontViewController)
        
        let rearNavigationController = UINavigationController(rootViewController: rearViewController)
        
        let revealController = SWRevealViewController(rearViewController: rearViewController, frontViewController: frontNavigationController)
        
        revealController.delegate = self
        revealController.rearViewRevealWidth = 200.0
        revealController.rearViewRevealOverdraw = 0.0
        revealController.frontViewShadowOpacity = 0.0
        revealController.bounceBackOnOverdraw = false
        revealController.bounceBackOnLeftOverdraw = false
        revealController.quickFlickVelocity = 1000000 // Disables quick Flicks
        revealViewController = revealController
        
        window!.rootViewController = revealViewController
        
        window!.backgroundColor = UIColor.whiteColor()
        window!.makeKeyAndVisible()
        
        // Set navigation bar and tab bar shadows throughout app, plus other appearances
        UINavigationBar.appearance().setBackgroundImage(UIImage(named: "navigationBarBackground"), forBarMetrics: UIBarMetrics.Default)
        UINavigationBar.appearance().shadowImage = UIImage(named: "navigationBarShadow")
        UINavigationBar.appearance().tintColor = UIColor.blue()
        UINavigationBar.appearance().barTintColor = UIColor.white()
        UITabBar.appearance().backgroundImage = UIImage(named: "tabBarBackground")
        UITabBar.appearance().shadowImage = UIImage(named: "tabBarShadow")
        
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
                //UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
                UIView.animateWithDuration(revealController.toggleAnimationDuration, animations: {
                    fnc.setOverlayAlpha(0.5)
                    })
            }
        } else if position.value == FrontViewPositionLeft.value {
            // If will move to hide side nav
            printlnC(pL, pG, "animate side nav to HIDDEN")
            if let fnc = revealController.frontViewController as? FrontNavigationControllerWithOverlay {
                //UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
                UIView.animateWithDuration(revealController.toggleAnimationDuration, animations: {
                        fnc.setOverlayAlpha(0.0)
                    })
            }
        }
    }
    
    func revealController(revealController: SWRevealViewController, panGestureMovedToLocation location: CGFloat, progress: CGFloat) {
        if let fnc = revealController.frontViewController as? FrontNavigationControllerWithOverlay {
            UIView.animateWithDuration(0.03, animations: {
                let progressDouble = Double(progress)
                fnc.setOverlayAlpha(CGFloat(customExponentialEaseOut(progressDouble) / 2.0))
                })
        }
    }
    
    func revealController(revealController: SWRevealViewController, panGestureBeganFromLocation location: CGFloat, progress: CGFloat) {
        if location < revealController.rearViewRevealWidth / 2.0 {
            // If pan began with side nav hidden, set the most recent pan start to FrontViewPositionLeft
            printlnC(pL, pG, "pan began with side nav HIDDEN")
            panGestureStartedFrom = FrontViewPositionLeft.value
            
            let pgVelocity = revealController.panGestureRecognizer().velocityInView(revealController.frontViewController.view)
            if pgVelocity.x > 0 {
                // If side nav is hidden and pan gesture is to the right side, hide the status bar
                // Fixes bug where swiping left while side nav is hidden still hides the status bar
                //UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
            }
        } else if location >= revealController.rearViewRevealWidth / 2.0 {
            // If pan began with side nav visible, set the most recent pan start to FrontViewPositionRight
            printlnC(pL, pG, "pan began with side nav VISIBLE")
            panGestureStartedFrom = FrontViewPositionRight.value
        }
    }
    
    func revealController(revealController: SWRevealViewController, panGestureEndedToLocation location: CGFloat, progress: CGFloat) {
        // Seems that this is the val SFReveal uses to decide where a paritally moved pan should go
        let criticalWidthDenom = CGFloat(2.0)
        
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
    