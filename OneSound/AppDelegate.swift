//
//  AppDelegate.swift
//  OneSound
//
//  Created by adam on 7/7/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit
import QuartzCore
import AVFoundation

let FacebookSessionChangeNotification = "FacebookSessionChangeNotification"
let facebookSessionPermissions = ["public_profile", "email"]
let FinishedLoginFlowNotification = "FinishedLoginFlowNotification"
let UserTableCellSmallFormat = "userTableCellSmall"
let guestUserImageForUserCell = UIImage(named: "guestUserImageForUserCell")

let thousandsFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
    formatter.formatterBehavior = NSNumberFormatterBehavior.BehaviorDefault
    return formatter
}()

let oneSoundDateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Format that the server sends back
    return formatter
}()

let validCharacters = "abcdefghijklmnopqrstuvwxyz1234567890"

let shorterPhoneLength = 480;
var shorterIphoneScreen = false;

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    var sideMenuViewController: SideNavigationViewController!
    var frontNavigationController: OSFrontNavigationController!
    
    let songTableViewImageCache = SDImageCache(namespace: "songTableViewImages")
    let currentSongImageCache = SDImageCache(namespace: "currentSongImages")
    let userCurrentSongImageCache = SDImageCache(namespace: "userCurrentSongImages")
    let userThumbnailImageCache = SDImageCache(namespace: "userThumbnailImages")
    
    var pL = false
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        NewRelicAgent.startWithApplicationToken("AAe6bc980a2d996add7c26db97bf6da4eef6a1a622")
        
        // Override point for customization after application launch.
        setupAppWindowAndViewHierarchy()
        
        setupAppDefaultBarAppearances()
        
        setupAppAFNetworkingTools()
        
        // Create the user manager
        UserManager.sharedUser
        
        // Create the party manager
        PartyManager.sharedParty
        PartyManager.sharedParty.prepareAfterInit()
        
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

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        println("applicationWillResignActive")
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        println("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        println("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBAppCall.handleDidBecomeActive()
        println("applicationDidBecomeActive")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        println("applicationWillTerminate")
    }
}

extension AppDelegate {
    // MARK: App launching related code

    // Setup side menu and general navigation hierarchy
    func setupAppWindowAndViewHierarchy() {
        // Setup the front nav controller to initially have the splash screen visible with a (determined) view controller as it's rootViewController
        // By default starts at the profile page (for now)
        // TODO: find the last saved row and nav to that
        sideMenuViewController = SideNavigationViewController()
        
        let rowInitiallySelected = sideMenuViewController.initiallySelectedRow
        println(rowInitiallySelected)
        let viewControllerToNavTo = sideMenuViewController.menuViewControllers[rowInitiallySelected]!
        let loggingInSplashViewController = LoggingInSpashViewController(nibName: LoggingInSpashViewControllerNibName, bundle: nil)
        
        frontNavigationController = OSFrontNavigationController(menuTableViewController: sideMenuViewController, contentViewController: viewControllerToNavTo)
        frontNavigationController.setViewControllers([viewControllerToNavTo, loggingInSplashViewController], animated: false)
        
        window!.rootViewController = frontNavigationController
        window!.backgroundColor = UIColor.whiteColor()
        window!.makeKeyAndVisible()
    }
    
    func setupAppAFNetworkingTools() {
        // Start monitoring network reachability
        AFNetworkReachabilityManager.sharedManager().startMonitoring()
        
        AFNetworkReachabilityManager.sharedManager().setReachabilityStatusChangeBlock({ reachability in
            if reachability == AFNetworkReachabilityStatus.NotReachable {
                
                println("Network has changed to UNreachable")
                // Make sure splash screen would get closed at this point in the Login Flow
                NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoginFlowNotification, object: nil)
                
                let alert = UIAlertView(title: "No Internet Connection", message: "Please connect to the internet to use \(appName)", delegate: nil, cancelButtonTitle: defaultAlertCancelButtonText)
                alert.tag = AlertTag.NoInternetConnection.rawValue
                AlertManager.sharedManager.showAlert(alert)
                
            } else if (reachability == AFNetworkReachabilityStatus.ReachableViaWiFi) || (reachability == AFNetworkReachabilityStatus.ReachableViaWWAN) {
                println("Network has changed to reachable")
                
                // Try setting up the user if network reachable but still not setup
                OSAPI.sharedClient.GETPublicInfo(
                    { data, responseObject in
                        let responseJSON = JSON(responseObject)
                        println(responseJSON)
                        
                        // Check that a supported version is being used
                        if let versionStatus = VersionStatus(rawValue: responseJSON["version_status"].int!) {
                            switch versionStatus {
                            case .Good, .Deprecated:
                                // Try setting up the user if network reachable but still not setup
                                if UserManager.sharedUser.setup == false {
                                    LoginFlowManager.sharedManager.startLoginFlow()
                                }
                            case .Block:
                                // Clear out party and user info, and show user the force updated VC
                                PartyManager.sharedParty.resetAllPartyInfo()
                                UserManager.sharedUser.setup = false
                                
                                // Make sure splash screen would get closed at this point in the Login Flow
                                NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoginFlowNotification, object: nil)
                                
                                let forceUpdateViewController = ForceUpdateViewController(nibName: ForceUpdateViewControllerNibName, bundle: nil)
                                self.frontNavigationController.presentViewController(forceUpdateViewController, animated: true, completion: nil)
                            }
                        
                        // Couldn't get a status number to check
                        } else {
                            // Try setting up the user if network reachable but still not setup
                            if UserManager.sharedUser.setup == false {
                                LoginFlowManager.sharedManager.startLoginFlow()
                            }
                        }

                    }, failure: defaultAFHTTPFailureBlock
                )
            }
        })
        
        // Start logging AFNetworking activiy
        AFNetworkActivityLogger.sharedLogger().startLogging()
        
        // Start showing network activity
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
    }
    
    func setupAppDefaultBarAppearances() {
        // Set navigation bar and tab bar shadows throughout app, plus other appearances
        // Doesn't work if trying to support iOS 7, moved to the OS base classes of VC, NavVC, TabVC
        
        /*
        if UINavigationBar.conformsToProtocol(UIAppearanceContainer) {
        UINavigationBar.appearance().setBackgroundImage(UIImage(named: "navigationBarBackground"), forBarMetrics: UIBarMetrics.Default)
        UINavigationBar.appearance().shadowImage = UIImage(named: "navigationBarShadow")
        UINavigationBar.appearance().tintColor = UIColor.blue()
        UINavigationBar.appearance().barTintColor = UIColor.white()
        UINavigationBar.appearance().translucent = true
        }
        
        if UITabBar.conformsToProtocol(UIAppearanceContainer) {
        UITabBar.appearance().backgroundImage = UIImage(named: "tabBarBackground")
        UITabBar.appearance().shadowImage = UIImage(named: "tabBarShadow")
        UITabBar.appearance().tintColor = UIColor.blue()
        UITabBar.appearance().barTintColor = UIColor.white()
        UITabBar.appearance().translucent = true
        }
        
        if UIToolbar.conformsToProtocol(UIAppearanceContainer) {
        UIToolbar.appearance().setBackgroundImage(UIImage(named: "toolbarBackground"), forToolbarPosition: UIBarPosition.Bottom, barMetrics: UIBarMetrics.Default)
        UIToolbar.appearance().setShadowImage(UIImage(named: "toolbarShadow"), forToolbarPosition: UIBarPosition.Bottom)
        UIToolbar.appearance().tintColor = UIColor.blue()
        UIToolbar.appearance().barTintColor = UIColor.white()
        UIToolbar.appearance().translucent = true
        }*/
    }
}

extension AppDelegate {
    // MARK: Facebook SDK related code
    
    // Manages results of all the actions taken outside the app (successful login/auth or cancellation)
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        
        // Set the state change handler before handleOpenURL just in case it was lost when app backgrounded
        FBSession.activeSession().setStateChangeHandler(
            { session, state, error in
                LoginFlowManager.sharedManager.facebookSessionStateChanged(session, state: state, error: error)
            }
        )
        
        return FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication)
    }
}

extension AppDelegate {
    override func remoteControlReceivedWithEvent(event: UIEvent) {
        let rc = event.subtype
        println("received remote control \(rc.rawValue)")
        let audioManager = PartyManager.sharedParty.audioManager
        
        switch rc {
        case .RemoteControlTogglePlayPause:
            if audioManager.state == .Playing {
                audioManager.onPauseButton()
            } else {
                audioManager.onPlayButton()
            }
        case .RemoteControlPlay:
            audioManager.onPlayButton()
        case .RemoteControlPause:
            audioManager.onPauseButton()
        default:
            break
        }
    }
}