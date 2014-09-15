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
    // TODO: Update these array extensions to work w/o bridging to Obj C if they become needed
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

class SwiftSet<T: Hashable> {
    var _underlyingSet: Dictionary<T, Bool>
    
    init() {
        _underlyingSet = Dictionary<T, Bool>()
    }
    
    subscript(k: T) -> Bool {
        if _underlyingSet[k] != nil {
            return true
        }
        else {
            return false
            }
    }
    
    func contains(k: T) -> Bool {
        return self[k]
    }
    
    func add(k: T) {
        _underlyingSet[k] = true
    }
    
    func remove(k: T) {
        _underlyingSet[k] = nil
    }
    
    func allObjects() -> [T] {
        return Array(_underlyingSet.keys)
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
    
    func replaceSubstringWithString(oldSubstring: String, newSubstring: String) -> String {
        let oldSubstrL: Int = countElements(oldSubstring)
        let stringL: Int = countElements(self)
        if (oldSubstrL <= stringL) && (oldSubstring != "") {
            for var i = 0; (i + oldSubstrL) <= stringL; ++i {
                let indexToStartAt = advance(self.startIndex, i)
                let indexToEndAt = advance(indexToStartAt, oldSubstrL)
                let substringRange = indexToStartAt..<indexToEndAt
                if self[substringRange] == oldSubstring {
                    let firstPartOfStringRange = self.startIndex..<indexToStartAt
                    let lastPartOfStringRange = indexToEndAt..<self.endIndex
                    return self[firstPartOfStringRange] + newSubstring + self[lastPartOfStringRange]
                }
            }
        }
        return self
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

func dispatchSyncToMainQueue(action closure:actionClosure) {
    dispatch_sync(dispatch_get_main_queue()) {
        closure()
    }
}

func downloadImageWithURLString(urlString: String, completion: (success: Bool, image: UIImage?) -> () ) {
    let request = NSMutableURLRequest(URL: NSURL(string: urlString))
    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(),
        completionHandler: { response, data, error in
            if error != nil {
                let image = UIImage(data: data)
                completion(success: true, image: image)
            } else {
                completion(success: false, image: nil)
            }
        }
    )
}

func cropImageCenterFromSideEdgesWhilePreservingAspectRatio(withWidth width: CGFloat, withHeight height: CGFloat, image originalImage: UIImage) -> UIImage {
    
    let originalSize = originalImage.size
    let scaleFactorForHeight = originalSize.width / width
    let newHeight = scaleFactorForHeight * height
    
    let posX: CGFloat = 0
    let posY: CGFloat = (originalSize.height / 2.0 ) - (newHeight / 2.0)
    
    let cropSquare = CGRectMake(posX, posY, originalSize.width, newHeight)
    
    // Performs the image cropping
    let imageRef = CGImageCreateWithImageInRect(originalImage.CGImage, cropSquare) // Automatically memory managed
    let newImage = UIImage(CGImage: imageRef, scale: originalImage.scale, orientation: originalImage.imageOrientation)

    return newImage
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

func timeInSecondsToFormattedMinSecondTimeLabelString(durationInSeconds: Int!) -> String {
    if durationInSeconds != nil {
        let numberOfMinutes: Int = durationInSeconds / 60
        let numberOfRemainingSeconds: Int = durationInSeconds % 60
        if numberOfRemainingSeconds < 10 {
            return "\(numberOfMinutes):0\(numberOfRemainingSeconds)"
        } else {
            return "\(numberOfMinutes):\(numberOfRemainingSeconds)"
        }
    } else {
        return "no duration"
    }
}

func timeInMillisecondsToFormattedMinSecondTimeLabelString(durationInMilliseconds: Int!) -> String {
    if durationInMilliseconds != nil {
        let timeInSeconds: Int = durationInMilliseconds / 1000
        let numberOfMinutes: Int = timeInSeconds / 60
        let numberOfRemainingSeconds: Int = timeInSeconds % 60
        if numberOfRemainingSeconds < 10 {
            return "\(numberOfMinutes):0\(numberOfRemainingSeconds)"
        } else {
            return "\(numberOfMinutes):\(numberOfRemainingSeconds)"
        }
    } else {
        return "no duration"
    }
}

func replaceSpacesWithASCIISpaceCodeForURL(urlString: String) -> String {
    return urlString.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: nil, range: nil)
}

func setupTHLabelToDefaultDesiredLook(label: THLabel!) {
    if label != nil {
        label.textColor = UIColor.white()
        label.shadowColor = UIColor(white: 0, alpha: 0.5)
        label.shadowOffset = CGSizeMake(0, 0)
        label.shadowBlur = 3.0
        label.strokeSize = 1.0
        label.strokeColor = UIColor.black()
        label.fadeTruncatingMode = THLabelFadeTruncatingMode.Tail
        label.clipsToBounds = false
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

// Convenient conditional printing
func printlnC(l: Bool, g: Bool, m: String) {
    if l || g {
        println(m)
    }
}