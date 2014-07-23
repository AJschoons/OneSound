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

extension String {
    func hasSubstringCaseSensitive(substring: String) -> Bool {
        let substringLength: Int = countElements(substring)
        let stringLength: Int = countElements(self)
        if (substringLength <= stringLength) && (substring != "") {
            for var i = 0; (i + substringLength) <= stringLength; ++i {
                let indexToStartAt = advance(self.startIndex, i)
                let indexToEndAt = advance(indexToStartAt, substringLength)
                let range = indexToStartAt..<indexToEndAt
                if self[range] == substring {
                    return true
                }
            }
        } else {
            return false
        }
        return false
    }
    
    func hasSubstringCaseInsensitive(substring: String) -> Bool {
        let substringLowercase = substring.lowercaseString
        let stringLowercase = self.lowercaseString
        let substringLength = countElements(substringLowercase)
        let stringLength = countElements(stringLowercase)
        if (substringLength <= stringLength) && (substring != "") {
            for var i = 0; (i + substringLength) <= stringLength; ++i {
                let indexToStartAt = advance(stringLowercase.startIndex, i)
                let indexToEndAt = advance(indexToStartAt, substringLength)
                let range = indexToStartAt..<indexToEndAt
                if stringLowercase[range] == substringLowercase {
                    return true
                }
            }
        } else {
            return false
        }
        return false
    }
}

extension UIColor {
    // Creates a UIColor from a Hex string.
    class func colorWithHexString (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(advance(cString.startIndex, 1))
        }
        
        if (countElements(cString) != 6) {
            return UIColor.grayColor()
        }
        
        var rString = cString.substringToIndex(advance(cString.startIndex, 2))
        var gString = cString.substringFromIndex(advance(cString.startIndex, 2)).substringToIndex(advance(cString.startIndex, 2))
        var bString = cString.substringFromIndex(advance(cString.startIndex, 4)).substringToIndex(advance(cString.startIndex, 2))
        
        //var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        var r: UInt32 = 0, g: UInt32 = 0, b: UInt32 = 0
        NSScanner.scannerWithString(rString).scanHexInt(&r)
        NSScanner.scannerWithString(gString).scanHexInt(&g)
        NSScanner.scannerWithString(bString).scanHexInt(&b)
        
        return UIColor(red: CGFloat(Int(r)) / 255.0, green: CGFloat(Int(g)) / 255.0, blue: CGFloat(Int(b)) / 255.0, alpha: CGFloat(1))
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

func downloadImageWithURLString(urlString: String, completion: (success: Bool, image: UIImage?) -> () ) {
    let request = NSMutableURLRequest(URL: NSURL(string: urlString))
    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(),
        completionHandler: { response, data, error in
            if !error {
                let image = UIImage(data: data)
                completion(success: true, image: image)
            } else {
                completion(success: false, image: nil)
            }
        }
    )
}

func cropBiggestCenteredSquareImageFromImage(image: UIImage, sideLength side: CGFloat) -> UIImage {
    // Get size of current image
    let size = image.size
    if (size.width == size.height) && (size.width == side) {
        return image
    }
    
    let newSize = CGSizeMake(side, side)
    var ratio: Double
    var delta: Double
    var offset: CGPoint
    
    // Make a new square size that is the resized image width
    let sz = CGSizeMake(newSize.width, newSize.width)
    
    // Figure out if the picture is landscape or portrait, then calculate scale factor and offset
    if image.size.width > image.size.height {
        ratio = Double(newSize.height / image.size.height)
        delta = ratio * Double((image.size.width - image.size.height))
        offset = CGPointMake(CGFloat(delta) / 2, 0)
    } else {
        ratio = Double(newSize.width / image.size.width)
        delta = ratio * Double((image.size.height - image.size.width))
        offset = CGPointMake(0, CGFloat(delta) / 2)
    }
    
    // Make the final clipping rect based on the calculated values
    let clipRect = CGRectMake(-offset.x, -offset.y, CGFloat(ratio) * image.size.width, CGFloat(ratio) * image.size.height)
    
    // Start a new context, with scale factor 0.0 so retina displays get high quality image
    if UIScreen.mainScreen().respondsToSelector("scale") {
        UIGraphicsBeginImageContextWithOptions(sz, true, 0.0)
    } else {
        UIGraphicsBeginImageContext(sz)
    }
    UIRectClip(clipRect)
    image.drawInRect(clipRect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
}

func formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat num: Int, baseOfNumber base: Int, postfix: String) -> String {
    let numWas1000OrGreater = (num > 999) ? true : false
    
    if numWas1000OrGreater {
        let digitsFromBase = abs(Int(num / base))
        
        if digitsFromBase < 1000  {
            switch digitsFromBase {
            case 0...9:
                let tenthsDigit = Int(num / (base / 10)) % 10
                if tenthsDigit > 0 {
                    return "\(digitsFromBase).\(tenthsDigit)\(postfix)"
                } else {
                    return "\(digitsFromBase)\(postfix)"
                }
            default:
                return "\(digitsFromBase)\(postfix)"
            }
        } else {
            println("Error: Int(num / base) must leave max of three leading integers from base")
            return "ERR"
        }
        
    } else {
        // Num was 0-999, so just return the num
        return "\(abs(num))"
    }
}

func intFormattedToShortStringForDisplay(num: Int) -> String {
    let posNum = abs(num)
    switch posNum {
    case 0...999:
        return String(posNum)
    case 1000...999999:
        return formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: posNum, baseOfNumber: 100, "k")
    case 1000000...999999999:
        return formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: posNum, baseOfNumber: 100, "M")
    default:
        return "MAX"
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