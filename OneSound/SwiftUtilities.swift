//
//  SwiftUtilities.swift
//
//
//  Created by adam on 6/19/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation
import UIKit

typealias completionBlock = () -> ()
typealias actionBlock = () -> ()
typealias completionClosure = () -> ()
typealias actionClosure = () -> ()

extension Array {
    func contains(#object:AnyObject) -> Bool {
        return self.bridgeToObjectiveC().containsObject(object)
    }
    
    func indexOf(#object:AnyObject) -> Int {
        return self.bridgeToObjectiveC().indexOfObject(object)
    }
    
    mutating func moveObjectAtIndex(fromIndex: Int, toIndex: Int) {
        if ((fromIndex == toIndex) || (fromIndex > self.count) ||
            (toIndex > self.count)) {
                return
        }
        // Get object being moved so it can be re-inserted
        let object = self[fromIndex]
        
        // Remove object from array
        self.removeAtIndex(fromIndex)
        
        // Insert object in array at new location
        self.insert(object, atIndex: toIndex)
    }
}

extension UIColor {
    // Creates a UIColor from a Hex string.
    class func colorWithHexString (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(1)
        }
        
        if (countElements(cString) != 6) {
            return UIColor.grayColor()
        }
        
        var rString = cString.substringToIndex(2)
        var gString = cString.substringFromIndex(2).substringToIndex(2)
        var bString = cString.substringFromIndex(4).substringToIndex(2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        NSScanner.scannerWithString(rString).scanHexInt(&r)
        NSScanner.scannerWithString(gString).scanHexInt(&g)
        NSScanner.scannerWithString(bString).scanHexInt(&b)
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
        
    }
}

func delayOnMainQueueFor(numberOfSeconds delay:Double, action closure:actionClosure) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue()) {
            closure()
    }
}

func dispatchAsyncToMainQueue(action closure:actionClosure) {
    dispatch_async(dispatch_get_main_queue()) {
        closure()
    }
}

func customCurveEaseInOut(xVal: Double, alphaPower: Double = 2.0) -> Double {
    if (xVal <= 1) && (xVal >= 0) {
        return (pow(xVal, alphaPower) / ( pow(xVal, alphaPower) + pow((1 - xVal), alphaPower) ))
    } else {
        return -1
    }
}

func customExponentialEaseOut(xVal: Double) -> Double {
    if (xVal <= 1) && (xVal >= 0) {
        return (-pow(2, (-10 * xVal)) + 1)
    } else {
        return -1
    }
}

// Convenient coditional printing
func printlnC(l: Bool, g: Bool, m: String) {
    if l || g {
        println(m)
    }
}