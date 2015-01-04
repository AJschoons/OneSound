//
//  SideMenu.swift
//  SwiftSideMenu
//
//  Created by Evgeny on 24.07.14.
//  Copyright (c) 2014 Evgeny Nazarov. All rights reserved.
//

import UIKit

@objc public protocol ENSideMenuDelegate {
    optional func sideMenuWillOpen()
    optional func sideMenuWillClose()
    optional func getOverlay() -> UIView?
}

@objc public protocol ENSideMenuProtocol {
    var sideMenu : ENSideMenu? { get }
    func setContentViewController(contentViewController: UIViewController)
}

public enum ENSideMenuAnimation : Int {
    case None
    case Default
}

public enum ENSideMenuPosition : Int {
    case Left
    case Right
}

public extension UIViewController {
    
    public func toggleSideMenuView () {
        sideMenuController()?.sideMenu?.toggleMenu()
    }
    
    public func hideSideMenuView () {
        sideMenuController()?.sideMenu?.hideSideMenu()
    }
    
    public func showSideMenuView () {
        
        sideMenuController()?.sideMenu?.showSideMenu()
    }
    
    internal func sideMenuController () -> ENSideMenuProtocol? {
        var iteration : UIViewController? = self.parentViewController
        if (iteration == nil) {
            return topMostController()
        }
        do {
            if (iteration is ENSideMenuProtocol) {
                return iteration as? ENSideMenuProtocol
            } else if (iteration?.parentViewController != nil && iteration?.parentViewController != iteration) {
                iteration = iteration!.parentViewController;
            } else {
                iteration = nil;
            }
        } while (iteration != nil)
        
        return iteration as? ENSideMenuProtocol
    }
    
    internal func topMostController () -> ENSideMenuProtocol? {
        var topController : UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController
        while (topController?.presentedViewController is ENSideMenuProtocol) {
            topController = topController?.presentedViewController;
        }
        
        return topController as? ENSideMenuProtocol
    }
}

public class ENSideMenu : NSObject {
    
    public var menuWidth : CGFloat = 160.0 {
        didSet {
            needUpdateApperance = true
            updateFrame()
        }
    }
    private let menuPosition:ENSideMenuPosition = .Left
    public var bouncingEnabled :Bool = true
    private let sideMenuContainerView =  UIView()
    public var menuTableViewController : UITableViewController!
    private var animator : UIDynamicAnimator!
    private let sourceView : UIView!
    private var needUpdateApperance : Bool = false
    public weak var delegate : ENSideMenuDelegate?
    private var isMenuOpen : Bool = false
    
    var userImage: UIImageView!
    
    var blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
    var blurView: UIVisualEffectView!
    var vibrancyView: UIVisualEffectView!
    
    private var pushMag: CGFloat = 20
    private var gravMag: CGFloat = 2
    
    public init(sourceView: UIView, menuPosition: ENSideMenuPosition) {
        super.init()
        self.sourceView = sourceView
        self.menuPosition = menuPosition
        self.setupMenuView()
    
        animator = UIDynamicAnimator(referenceView:sourceView)
        
        // Add right swipe gesture recognizer
        let rightSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleGesture:")
        rightSwipeGestureRecognizer.direction =  UISwipeGestureRecognizerDirection.Right
        sourceView.addGestureRecognizer(rightSwipeGestureRecognizer)
        
        // Add left swipe gesture recognizer
        let leftSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleGesture:")
        leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Left
        
        if (menuPosition == .Left) {
            sourceView.addGestureRecognizer(rightSwipeGestureRecognizer)
            sideMenuContainerView.addGestureRecognizer(leftSwipeGestureRecognizer)
        }
        else {
            sideMenuContainerView.addGestureRecognizer(rightSwipeGestureRecognizer)
            sourceView.addGestureRecognizer(leftSwipeGestureRecognizer)
        }
        
    }

    public convenience init(sourceView: UIView, menuTableViewController: UITableViewController, menuPosition: ENSideMenuPosition) {
        self.init(sourceView: sourceView, menuPosition: menuPosition)
        self.menuTableViewController = menuTableViewController
        self.menuTableViewController.tableView.frame = sideMenuContainerView.bounds
        self.menuTableViewController.tableView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        sideMenuContainerView.addSubview(self.menuTableViewController.tableView)
        
        let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        
        // set the vibrancy frame to effect everything
        let smcvBounds = sideMenuContainerView.bounds
        let vibrancyViewFrame = CGRectMake(smcvBounds.origin.x, smcvBounds.origin.y + sideNavigationUserCellUserImageBottomDisanceFromTop, smcvBounds.size.width, smcvBounds.size.height - sideNavigationUserCellUserImageBottomDisanceFromTop)
        vibrancyView.frame = smcvBounds
        
        vibrancyView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        vibrancyView.contentView.addSubview(menuTableViewController.view)
        blurView.contentView.addSubview(vibrancyView)
    }
    
    private func updateFrame() {
        let menuFrame = CGRectMake(
            (menuPosition == .Left) ?
                isMenuOpen ? 0 : -menuWidth-1.0 :
                isMenuOpen ? sourceView.frame.size.width - menuWidth : sourceView.frame.size.width+1.0,
            sourceView.frame.origin.y,
            menuWidth,
            sourceView.frame.size.height
        )
        
        sideMenuContainerView.frame = menuFrame
    }

    private func setupMenuView() {
        
        // Configure side menu container
        updateFrame()

        sideMenuContainerView.backgroundColor = UIColor.clearColor()
        sideMenuContainerView.clipsToBounds = false
        sideMenuContainerView.layer.masksToBounds = false;
        sideMenuContainerView.layer.shadowOffset = (menuPosition == .Left) ? CGSizeMake(1.0, 1.0) : CGSizeMake(-1.0, -1.0);
        sideMenuContainerView.layer.shadowRadius = 1.0;
        sideMenuContainerView.layer.shadowOpacity = 0.125;
        sideMenuContainerView.layer.shadowPath = UIBezierPath(rect: sideMenuContainerView.bounds).CGPath
        
        sourceView.addSubview(sideMenuContainerView)
        
        if (NSClassFromString("UIVisualEffectView") != nil) {
            // Add blur view
            blurEffect = UIBlurEffect(style: .Light)
            blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = sideMenuContainerView.bounds
            blurView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
            sideMenuContainerView.addSubview(blurView)
        }
        
        userImage = UIImageView()
        userImage.setTranslatesAutoresizingMaskIntoConstraints(false)
        userImage.backgroundColor = UIColor.red()
        sideMenuContainerView.addSubview(userImage)
        
        userImage.addConstraint(NSLayoutConstraint(item: userImage, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 100))
        userImage.addConstraint(NSLayoutConstraint(item: userImage, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 100))
        
        sideMenuContainerView.addConstraint(NSLayoutConstraint(item: userImage, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: sideMenuContainerView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
        sideMenuContainerView.addConstraint(NSLayoutConstraint(item: userImage, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: sideMenuContainerView, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 64 + userImageDistanceFromTopOfSideNavigationUserCell))
    }
    
    private func toggleMenu(shouldOpen: Bool) {
        updateSideMenuApperanceIfNeeded()
        isMenuOpen = shouldOpen
        if (bouncingEnabled) {
            
            animator.removeAllBehaviors()
            
            var gravityDirectionX: CGFloat
            var pushMagnitude: CGFloat
            var boundaryPointX: CGFloat
            var boundaryPointY: CGFloat
            
            if (menuPosition == .Left) {
                // Left side menu
                gravityDirectionX = (shouldOpen) ? gravMag : -gravMag
                pushMagnitude = (shouldOpen) ? pushMag : -pushMag
                boundaryPointX = (shouldOpen) ? menuWidth : -menuWidth-2
                boundaryPointY = 20
            }
            else {
                // Right side menu
                gravityDirectionX = (shouldOpen) ? -gravMag : gravMag
                pushMagnitude = (shouldOpen) ? -pushMag : pushMag
                boundaryPointX = (shouldOpen) ? sourceView.frame.size.width-menuWidth : sourceView.frame.size.width+menuWidth+2
                boundaryPointY =  -20
            }
            
            let gravityBehavior = UIGravityBehavior(items: [sideMenuContainerView])
            gravityBehavior.gravityDirection = CGVectorMake(gravityDirectionX,  0)
            animator.addBehavior(gravityBehavior)
            
            let collisionBehavior = UICollisionBehavior(items: [sideMenuContainerView])
            collisionBehavior.addBoundaryWithIdentifier("menuBoundary", fromPoint: CGPointMake(boundaryPointX, boundaryPointY),
                toPoint: CGPointMake(boundaryPointX, sourceView.frame.size.height))
            animator.addBehavior(collisionBehavior)
            
            let pushBehavior = UIPushBehavior(items: [sideMenuContainerView], mode: UIPushBehaviorMode.Instantaneous)
            pushBehavior.magnitude = pushMagnitude
            animator.addBehavior(pushBehavior)
            
            let menuViewBehavior = UIDynamicItemBehavior(items: [sideMenuContainerView])
            menuViewBehavior.elasticity = 0.25
            animator.addBehavior(menuViewBehavior)
            
        }
        else {
            var destFrame : CGRect
            let containerViewHeight = sideMenuContainerView.frame.size.height
            let sourceViewWidth = sourceView.frame.size.width
            
            if (menuPosition == .Left) {
                destFrame = CGRectMake((shouldOpen) ? -2.0 : -menuWidth, 0, menuWidth, containerViewHeight)
            }
            else {
                destFrame = CGRectMake((shouldOpen) ? sourceViewWidth-menuWidth : sourceViewWidth+2.0,
                                        0,
                                        menuWidth,
                                        containerViewHeight)
            }
            
            let destOverlayAlpha: CGFloat = (shouldOpen) ? 0.5 : 0.0
            
            let destOverlayFrameOriginX = destFrame.origin.x + destFrame.size.width
            let destOverlayFrame = CGRectMake(destOverlayFrameOriginX, 64, sourceViewWidth - destOverlayFrameOriginX, containerViewHeight - 64)
            
            let delegateOverlayView = delegate?.getOverlay?()
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.sideMenuContainerView.frame = destFrame
                delegateOverlayView?.alpha = destOverlayAlpha
                delegateOverlayView?.frame = destOverlayFrame
            })
        }
        
        if (shouldOpen) {
            delegate?.sideMenuWillOpen?()
        } else {
            delegate?.sideMenuWillClose?()
        }
    }
    
    internal func handleGesture(gesture: UISwipeGestureRecognizer) {
        toggleMenu((self.menuPosition == .Right && gesture.direction == .Left)
                || (self.menuPosition == .Left && gesture.direction == .Right))
    }
    
    private func updateSideMenuApperanceIfNeeded () {
        if (needUpdateApperance) {
            var frame = sideMenuContainerView.frame
            frame.size.width = menuWidth
            sideMenuContainerView.frame = frame
            sideMenuContainerView.layer.shadowPath = UIBezierPath(rect: sideMenuContainerView.bounds).CGPath

            needUpdateApperance = false
        }
    }
    
    public func toggleMenu () {
        if (isMenuOpen) {
            toggleMenu(false)
        }
        else {
            updateSideMenuApperanceIfNeeded()
            toggleMenu(true)
        }
    }
    
    public func showSideMenu () {
        if (!isMenuOpen) {
            toggleMenu(true)
        }
    }
    
    public func hideSideMenu () {
        if (isMenuOpen) {
            toggleMenu(false)
        }
    }
}

