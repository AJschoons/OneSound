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
let facebookSessionPermissions = ["public_profile", "email"]
let FinishedLoginFlowNotification = "FinishedLoginFlowNotification"
let UserTableCellSmallFormat = "userTableCellSmall"
let guestUserImageForUserCell = UIImage(named: "guestUserImageForUserCell")

let loadingOSLogo0 = UIImage(named: "loadingOneSoundOne0")!
let loadingOSLogo1 = UIImage(named: "loadingOneSoundOne1")!
let loadingOSLogo2 = UIImage(named: "loadingOneSoundOne2")!

let loadingSong0 = UIImage(named: "loadingSong0")!
let loadingSong1 = UIImage(named: "loadingSong1")!
let loadingSong2 = UIImage(named: "loadingSong2")!

let thousandsFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
    formatter.formatterBehavior = NSNumberFormatterBehavior.BehaviorDefault
    return formatter
}()

let validCharacters = "abcdefghijklmnopqrstuvwxyz1234567890"

let shorterPhoneLength = 480;
var shorterIphoneScreen = false;

var errorAlertIsShowing = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    var revealViewController: SWRevealViewController?
    var panGestureStartedFrom: FrontViewPosition = FrontViewPosition.RightMostRemoved
    // FrontViewPosition.RightMostRemoved so it won't init as a used/relevant enum val
    
    var songTableViewImageCache = SDImageCache(namespace: "songTableViewImages")
    var songImageCache = SDImageCache(namespace: "songImages")
    var userMainPartyImageCache = SDImageCache(namespace: "userMainPartyImages")
    var userThumbnailImageCache = SDImageCache(namespace: "userThumbnailImages")
    
    var pL = false

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        // Override point for customization after application launch.
        setupAppWindowAndViewHierarchy()
        
        setupAppDefaultBarAppearances()
        
        setupAppAFNetworkingTools()
        
        // Create the user
        LocalUser.sharedUser
        //LocalUser.sharedUser.deleteAllSavedUserInformation()
        
        // Login flow is handled by AFNetworkingReachability manager and FBLogin status change
        
        // Loads the FBLoginView before the view is shown
        FBLoginView.self
        
        // Should help the AVAudioPlayer move to the next song when in background
        // Also needed for home screen control and AirPlay
        // http://stackoverflow.com/questions/9660488/ios-avaudioplayer-doesnt-continue-to-next-song-while-in-background
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        // Set to true if the iPhone screen is the 4S length
        // App is only in portrait orientation
        if UIScreen.mainScreen().bounds.height < 500 {
            shorterIphoneScreen = true
        }
        
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
        // Whenever a person opens the app, check for a cached session
        if FBSession.activeSession().state == FBSessionState.CreatedTokenLoaded {
            // If there IS one, just open the session silently, w/o showing the user the login UI
            println("Cached facebook token found")
            
            FBSession.openActiveSessionWithReadPermissions(facebookSessionPermissions, allowLoginUI: false,
                completionHandler: { session, state, error in
                    // Handler for session state changes
                    // This method will be called EACH time the session state changes,
                    // also for intermediate states and NOT just when the session open
                    self.sessionStateChanged(session, state: state, error: error)
                }
            )
        } else {
            // If no facebook token, check for guest user
            println("Cached facebook token unavailable, check for guest user")
            
            var userID: Int? = SSKeychain.passwordForService(service, account: userIDKeychainKey) != nil ? SSKeychain.passwordForService(service, account: userIDKeychainKey).toInt() : nil
            var userAPIToken: String? = SSKeychain.passwordForService(service, account: userAccessTokenKeychainKey)
            
            if userID == nil || userAPIToken == nil {
                // If no guest user, then request a guest user to be created, set it up, save in keychain, save to LocalUser
                println("Guest user NOT found")
                LocalUser.sharedUser.setupGuestAccount()
            } else {
                // Got guest user from keychain, request their information and save to LocalUser
                println("Guest user FOUND")
                LocalUser.sharedUser.signIntoGuestAccount(userID!, userAccessToken: userAPIToken!)
            }
        }
    }
    
    func setupAppWindowAndViewHierarchy() {
        // Setup side menu and general navigation hierarchy
    
        let rearViewController = SideNavigationViewController()
        
        let frontNavigationController = FrontNavigationController()
        let loggingInSplashViewController = LoggingInSpashViewController(nibName: LoggingInSpashViewControllerNibName, bundle: nil)
        
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

        // Setup the front nav controller to initially have the splash screen visible with a (determined) view controller as it's rootViewController
        let snc = revealController.rearViewController as SideNavigationViewController
        // By default starts at the profile page (for now)
        // TODO: find the last saved row and nav to that
        let rowInitiallySelected = snc.initiallySelectedRow
        println(rowInitiallySelected)
        let viewControllerToNavTo = snc.menuViewControllers[rowInitiallySelected]!
        frontNavigationController.setViewControllers([viewControllerToNavTo, loggingInSplashViewController], animated: false)
        
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
                // Make sure splash screen would get closed at this point in the Login Flow
                NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoginFlowNotification, object: nil)
                
                let alertView = UIAlertView(title: "No Internet Connection", message: "Please connect to the internet to use OneSound", delegate: nil, cancelButtonTitle: "Ok")
                alertView.show()
            } else if (reachability == AFNetworkReachabilityStatus.ReachableViaWiFi) || (reachability == AFNetworkReachabilityStatus.ReachableViaWWAN) {
                println("Network has changed to reachable")
                
                if LocalUser.sharedUser.setup == false {
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
        if error == nil && state == FBSessionState.Open { //FBSessionStateOpen {
            println("Facebook session state change: Open")
            
            let accessTokenData = session.accessTokenData
            let userFBAccessToken = accessTokenData.accessToken
            println("Facebook session access token:\(userFBAccessToken)")
            
            var userID: Int? = SSKeychain.passwordForService(service, account: userIDKeychainKey) != nil ? SSKeychain.passwordForService(service, account: userIDKeychainKey).toInt() : nil
            var userAPIToken: String? = SSKeychain.passwordForService(service, account: userAccessTokenKeychainKey)
            
            if userID != nil && userAPIToken != nil {
                println("Found userID and userAPIToken from keychain, sign in with Facebook account")
                
                println("userID from keychain:\(userID)")
                println("userAPIToken from keychain:\(userAPIToken)")
                println("userfbAuthToken:\(userFBAccessToken)")
                
                if userFBAccessToken != nil {
                    LocalUser.sharedUser.signIntoFullAccount(userID!, userAccessToken: userAPIToken!, fbAuthToken: userFBAccessToken)
                } else {
                    // Reset all data and let user know to sign back into facebook
                    // The Facebook SDK session state will change to closed / login failed, and will be handled accordingly
                    LocalUser.sharedUser.deleteAllSavedUserInformation(
                        completion: {
                            let alert = UIAlertView(title: "Facebook Information Expired", message: "The Facebook login information has expired. Please restart the app and sign in again. The temporary new guest account that has been provided does not have any information from the Facebook verified account", delegate: nil, cancelButtonTitle: "Ok")
                            alert.show()
                        }
                    )
                }
            } else {
                println("UserID and userAPIToken NOT found from keychain, setup guest user")
                LocalUser.sharedUser.setupGuestAccount()
            }
        } else if (state == FBSessionState.Closed) || (state == FBSessionState.ClosedLoginFailed) {
            // was using FBSessionStateClosed and FBSessionStateClosedLoginFailed until using forked facebook iOS SDK
            // If the session is closed, delete all old info and setup a guest account if the user had a full account
            println("Facebook session state change: Closed/Login Failed")
            
            if LocalUser.sharedUser.guest == false {
                println("User was NOT a guest; delete all their saved info & clear facebook token, setup new guest account")
                LocalUser.sharedUser.deleteAllSavedUserInformation(
                    completion: {
                        LocalUser.sharedUser.setupGuestAccount()
                    }
                )
            } else {
                // If user was a guest (could only occur during sign in...?) then just delete the facebook info
                println("User WAS a guest; clear facebook token")
                FBSession.activeSession().closeAndClearTokenInformation()
                // Make sure splash screen would get closed at this point in the Login Flow
                NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoginFlowNotification, object: nil)
            }
        } else if (error != nil) {
            println("Facebook session state change: Error")
            // Make sure splash screen would get closed at this point in the Login Flow
            NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoginFlowNotification, object: nil)
            
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
                    // TODO: figure out a way around this issue
                    /*
                    let errorMessageObject: AnyObject? = error.userInfo["com.facebook.sdk:ParsedJSONResponseKey"]?["body"]?["error"]?["message"]
                    
                    if let errorMessage = errorMessageObject as? String {
                        alertTitle = "Something went wrong"
                        alertText = "Please retry. If the problem persists contact us and mention this error code: \(errorMessage)"
                        let alert = UIAlertView(title: alertTitle, message: alertText, delegate: nil, cancelButtonTitle: "Ok")
                        alert.show()

                    }
                    */
                }
            }
            // Clear the token for all errors
            FBSession.activeSession().closeAndClearTokenInformation()
            // Show the user the logged out UI
        }
        NSNotificationCenter.defaultCenter().postNotificationName(FacebookSessionChangeNotification, object: nil)
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
        if position == FrontViewPosition.Right {
            // If will move to show side nav
            printlnC(pL, pG, "animate side nav to VISIBLE")
            
            if let fnc = revealController.frontViewController as? FrontNavigationControllerWithOverlay {
                //UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
                UIView.animateWithDuration(revealController.toggleAnimationDuration, animations: {
                    fnc.setOverlayAlpha(0.5)
                    })
            }
        } else if position == FrontViewPosition.Left {
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
            panGestureStartedFrom = FrontViewPosition.Left
            
            let pgVelocity = revealController.panGestureRecognizer().velocityInView(revealController.frontViewController.view)
            if pgVelocity.x > 0 {
                // If side nav is hidden and pan gesture is to the right side, hide the status bar
                // Fixes bug where swiping left while side nav is hidden still hides the status bar
                //UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
            }
        } else if location >= revealController.rearViewRevealWidth / 2.0 {
            // If pan began with side nav visible, set the most recent pan start to FrontViewPositionRight
            printlnC(pL, pG, "pan began with side nav VISIBLE")
            panGestureStartedFrom = FrontViewPosition.Right
        }
    }
    
    func revealController(revealController: SWRevealViewController, panGestureEndedToLocation location: CGFloat, progress: CGFloat) {
        // Seems that this is the val SFReveal uses to decide where a paritally moved pan should go
        let criticalWidthDenom = CGFloat(2.0)
        
        if panGestureStartedFrom == FrontViewPosition.Left {
            // If pan started with side nav HIDDEN
            printlnC(pL, pG, "pan ended after starting with side nav HIDDEN")
            if location >= revealController.rearViewRevealWidth / criticalWidthDenom {
                // If pan ended to the right of critical width point, make side nav VISIBLE
                printlnC(pL, pG, "    pan ended over 1/\(criticalWidthDenom) of the way to side nav VISIBLE, animate side nav to VISIBLE")
                revealController.setFrontViewPosition(FrontViewPosition.Right, animated: true)
            } else {
                // If pan ended to the left of critical width point, make side nav HIDDEN
                printlnC(pL, pG, "    pan didn't reach 1/\(criticalWidthDenom) of the way to side nav VISIBLE, animate side nav to HIDDEN")
                revealController.setFrontViewPosition(FrontViewPosition.Left, animated: true)
            }
        } else if panGestureStartedFrom == FrontViewPosition.Right {
            // If pan started with side nav VISIBLE
            printlnC(pL, pG, "pan ended after starting with side nav VISIBLE")
            if location <= (revealController.rearViewRevealWidth - (revealController.rearViewRevealWidth / criticalWidthDenom)) {
                // If pan ended to the left of critical width point, make side nav HIDDEN
                printlnC(pL, pG, "    pan ended over 1/\(criticalWidthDenom) of the way to side nav HIDDEN, animate side nav to HIDDEN")
                revealController.setFrontViewPosition(FrontViewPosition.Left, animated: true)
            } else {
                // If pan ended to the right of critical width point, make side nav VISIBLE
                printlnC(pL, pG, "    pan didn't reach 1/\(criticalWidthDenom) of the way to side nav HIDDEN, animate side nav to VISIBLE")
                revealController.setFrontViewPosition(FrontViewPosition.Right, animated: true)
            }
        }
    }
}
