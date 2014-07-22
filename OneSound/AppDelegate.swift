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
let FacebookSessionChangeNotification = "FacebookSessionChangeNotification"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    //var statusBarBackground: UIWindow?
    var revealViewController: SWRevealViewController?
    var panGestureStartedFrom: FrontViewPosition = FrontViewPositionRightMostRemoved
    // FrontViewPositionRightMostRemoved so it won't init as a used enum val
    
    var localUser: LocalUser!
    
    // Set to true to print everything in AppDelegate
    var pL = false

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        // Override point for customization after application launch.
        setupAppWindowAndViewHierarchy()
        
        setupAppDefaultBarAppearances()
        
        setupAppAFNetworkingTools()
        
        // Create the user
        localUser = LocalUser.sharedUser
        
        // Login flow is handled by AFNetworkingReachability mangaer
        
        // Loads the FBLoginView before the view is shown
        FBLoginView.self
        
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
        FBAppCall.handleDidBecomeActive()
    }

    func applicationWillTerminate(application: UIApplication!) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension AppDelegate {
    // MARK: App launching related code
    
    func setupAppLocalUserBySigningInWithLoginFlow() {
        // Always print login flow
        pL = true
        
        // Whenever a person opens the app, check for a cached session
        if FBSession.activeSession().state == FBSessionStateCreatedTokenLoaded {
            // If there IS one, just open the session silently, w/o showing the user the login UI
            FBSession.openActiveSessionWithReadPermissions(["public_profile"], allowLoginUI: false,
                completionHandler: { session, state, error in
                    // Handler for session state changes
                    // This method will be called EACH time the session state changes,
                    // also for intermediate states and NOT just when the session open
                    self.sessionStateChanged(session, state: state, error: error)
                }
            )
        }
        
        // Check for user facebook credentials
        var userFacebookUID: String? = SSKeychain.passwordForService(service, account: userFacebookUIDKeychainKey)
        var userFacebookAuthenticationToken: String? = SSKeychain.passwordForService(service, account: userFacebookAuthenticationTokenKeychainKey)
        
        userFacebookUID ? printlnC(pL, pG, "app launched with userFacebookUID:\(userFacebookUID)") : printlnC(pL, pG, "app launched without userFacebookUID")
        userFacebookAuthenticationToken ? printlnC(pL, pG, "app launched with userFacebookAuthenticationToken:\(userFacebookAuthenticationToken)") : printlnC(pL, pG, "app launched without userFacebookAuthenticationToken")
        
        if !userFacebookUID || !userFacebookAuthenticationToken {
            // If no facebook credentials, check for guest user
            printlnC(pL, pG, "facebook credentials unavailable, check for guest user")
            
            var userID: Int? = SSKeychain.passwordForService(service, account: userIDKeychainKey) ? SSKeychain.passwordForService(service, account: userIDKeychainKey).toInt() : nil
            var userAPIToken: String? = SSKeychain.passwordForService(service, account: userAPITokenKeychainKey)
            
            if !userID || !userAPIToken {
                // If no guest user, then request a guest user to be created, set it up, save in keychain, save to LocalUser
                localUser.setupLocalGuestUser()
            } else {
                // Got guest user from keychain, request their information and save to LocalUser
                localUser.fetchLocalGuestUser(userID!, apiToken: userAPIToken!)
            }
        } else {
            // Got facebook credentials from keychain
        }
        
        pL = false
    }
    
    func setupAppWindowAndViewHierarchy() {
        // Setup side menu and general navigation hierarchy
        
        let frontViewController = FrontViewController()
        let rearViewController = SideNavigationViewController()
        
        let frontNavigationController = FrontNavigationController(rootViewController: frontViewController)
        
        let rearNavigationController = UINavigationController(rootViewController: rearViewController)
        
        let revealController = SWRevealViewController(rearViewController: rearViewController, frontViewController: frontNavigationController)
        
        // Configure side menu
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
    }
    
    func setupAppDefaultBarAppearances() {
        // Set navigation bar and tab bar shadows throughout app, plus other appearances
        
        UINavigationBar.appearance().setBackgroundImage(UIImage(named: "navigationBarBackground"), forBarMetrics: UIBarMetrics.Default)
        UINavigationBar.appearance().shadowImage = UIImage(named: "navigationBarShadow")
        UINavigationBar.appearance().tintColor = UIColor.blue()
        UINavigationBar.appearance().barTintColor = UIColor.white()
        
        UITabBar.appearance().backgroundImage = UIImage(named: "tabBarBackground")
        UITabBar.appearance().shadowImage = UIImage(named: "tabBarShadow")
        UITabBar.appearance().tintColor = UIColor.blue()
        UITabBar.appearance().barTintColor = UIColor.white()
        
        UIToolbar.appearance().setBackgroundImage(UIImage(named: "toolbarBackground"), forToolbarPosition: UIBarPosition.Bottom, barMetrics: UIBarMetrics.Default)
        UIToolbar.appearance().setShadowImage(UIImage(named: "toolbarShadow"), forToolbarPosition: UIBarPosition.Bottom)
        UIToolbar.appearance().tintColor = UIColor.blue()
        UIToolbar.appearance().barTintColor = UIColor.white()
    }
    
    func setupAppAFNetworkingTools() {
        // Start monitoring network reachability
        AFNetworkReachabilityManager.sharedManager().startMonitoring()
        
        AFNetworkReachabilityManager.sharedManager().setReachabilityStatusChangeBlock({ reachability in
            if reachability == AFNetworkReachabilityStatus.NotReachable {
                println("Network has changed to UNreachable")
                
                let alertView = UIAlertView(title: "No Internet Connection", message: "Please connect to the internet to use OneSound", delegate: nil, cancelButtonTitle: "Ok")
                alertView.show()
            } else if (reachability == AFNetworkReachabilityStatus.ReachableViaWiFi) || (reachability == AFNetworkReachabilityStatus.ReachableViaWWAN) {
                println("Network has changed to reachable")
                
                if !self.localUser.setup {
                    // Try setting up the user if network reachable but still not setup
                    self.setupAppLocalUserBySigningInWithLoginFlow()
                }
            }
        })
        
        // Start logging AFNetworking activiy
        AFNetworkActivityLogger.sharedLogger().startLogging()
        
        // Start showing network activity
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
    }
}

extension AppDelegate {
    // MARK: Facebook SDK related code
    
    func sessionStateChanged(session: FBSession, state: FBSessionState, error: NSError!) {
        // Handles ALL the session state changes in the app
        
        // Handle the session state
        // Usually the only interesting states are opened session, closed session, and failed login
        if !error && state == FBSessionStateOpen {
            let accessTokenData = session.accessTokenData
            let userFBAccessToken = accessTokenData.accessToken
            let userFBID = accessTokenData.userID
            println("accessToken:\(userFBAccessToken)   userID:\(userFBID)")
        } else if (state == FBSessionStateClosed) || (state == FBSessionStateClosedLoginFailed) {
            // If the session is closed
            // Show the user the logged-out UI
        } else if error {
            var alertText: String?
            var alertTitle: String?
            // If the error requires people using an app to make an action outside of the app in order to recover
            if FBErrorUtility.shouldNotifyUserForError(error) == true {
                alertTitle = "Session Error"
                alertText = FBErrorUtility.userMessageForError(error)
                let alert = UIAlertView(title: alertTitle, message: alertText, delegate: nil, cancelButtonTitle: "Ok")
                alert.show()
            } else {
                // If the user cancelled login, do nothing
                if FBErrorUtility.errorCategoryForError(error) == FBErrorCategory.UserCancelled {
                    println("User cancelled login")
                } else if FBErrorUtility.errorCategoryForError(error) == FBErrorCategory.AuthenticationReopenSession {
                    // If session closure outside of the app happened
                    alertTitle = "Session Error"
                    alertText = "Your Facebook current session is no longer valid. Please log in again."
                    let alert = UIAlertView(title: alertTitle, message: alertText, delegate: nil, cancelButtonTitle: "Ok")
                    alert.show()
                } else {
                    // All other errors handled with generic message
                    // Get more info from the error
                    let errorInformation = error.userInfo.bridgeToObjectiveC().objectForKey("com.facebook.sdk:ParsedJSONResponseKey").objectForKey("body").objectForKey("error") as NSDictionary
                    let errorMessage = errorInformation.objectForKey("message") as String
                    
                    alertTitle = "Something went wrong"
                    alertText = "Please retry. If the problem persists contact us and mention this error code: \(errorMessage)"
                    let alert = UIAlertView(title: alertTitle, message: alertText, delegate: nil, cancelButtonTitle: "Ok")
                    alert.show()
                }
            }
            // Clear the token for all errors
            FBSession.activeSession().closeAndClearTokenInformation()
            // Show the user the logged out UI
        }
    }
    
    // Manages results of all the actions taken outside the app (successful login/auth or cancellation)
    func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool {
        return FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication)
    }
}

extension AppDelegate: SWRevealViewControllerDelegate {
    // MARK: SWRevealViewController Delegate methods
    // Customizes fading of whatever Front Navigation Controller is conforming to FrontNavigationControllerWithOverlay protocol
    
    func revealController(revealController: SWRevealViewController, animateToPosition position: FrontViewPosition) {
        if position == FrontViewPositionRight {
            // If will move to show side nav
            printlnC(pL, pG, "animate side nav to VISIBLE")
            
            if let fnc = revealController.frontViewController as? FrontNavigationControllerWithOverlay {
                //UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
                UIView.animateWithDuration(revealController.toggleAnimationDuration, animations: {
                    fnc.setOverlayAlpha(0.5)
                    })
            }
        } else if position == FrontViewPositionLeft {
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
            panGestureStartedFrom = FrontViewPositionLeft
            
            let pgVelocity = revealController.panGestureRecognizer().velocityInView(revealController.frontViewController.view)
            if pgVelocity.x > 0 {
                // If side nav is hidden and pan gesture is to the right side, hide the status bar
                // Fixes bug where swiping left while side nav is hidden still hides the status bar
                //UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
            }
        } else if location >= revealController.rearViewRevealWidth / 2.0 {
            // If pan began with side nav visible, set the most recent pan start to FrontViewPositionRight
            printlnC(pL, pG, "pan began with side nav VISIBLE")
            panGestureStartedFrom = FrontViewPositionRight
        }
    }
    
    func revealController(revealController: SWRevealViewController, panGestureEndedToLocation location: CGFloat, progress: CGFloat) {
        // Seems that this is the val SFReveal uses to decide where a paritally moved pan should go
        let criticalWidthDenom = CGFloat(2.0)
        
        if panGestureStartedFrom == FrontViewPositionLeft {
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
        } else if panGestureStartedFrom == FrontViewPositionRight {
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
    