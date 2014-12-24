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
        NSScanner(string: rString).scanHexInt(&r)
        NSScanner(string: gString).scanHexInt(&g)
        NSScanner(string: bString).scanHexInt(&b)
        
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
    let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(),
        completionHandler: { response, data, error in
            if error != nil {
                let image = UIImage(data: data)
                completion(success: true, image: image)
            } else {
                completion(success: false, image: nil)
                println("ERROR DOWNLOADING IMAGE")
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

    return newImage!
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

func setupOSLabelToDefaultDesiredLook(label: OSLabel!) {
    if label != nil {
        label.textColor = UIColor.white()
        label.layer.shadowColor = UIColor.blackColor().CGColor
        label.layer.shadowRadius = 1.0
        label.layer.shadowOpacity = 1.0
        label.layer.shadowOffset = CGSizeZero
        label.clipsToBounds = false
        label.adjustsFontSizeToFitWidth = true
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


func setUserInfoLabelsText(# upvoteLabel: UILabel!, # numUpvotes: Int, # songLabel: UILabel!, # numSongs: Int, # hotnessLabel: UILabel!, # percentHotness: Int, userNameLabel: UILabel? = nil, userName: String? = nil) {
    upvoteLabel.text = intFormattedToShortStringForDisplay(numUpvotes)
    songLabel.text = intFormattedToShortStringForDisplay(numSongs)
    hotnessLabel.text = "\(percentHotness)%"
    
    if userNameLabel != nil && userName != nil {
        userNameLabel!.text = userName!
    }
}

func addingOnlyWhitespaceToTextFieldWithOnlyWhitespaceOrEmpty(textfieldText: String, textToAdd: String) -> Bool {
    // Check if the text field already has any non-whitespace characters
    var textFieldHasNonWhitespaceChar = false
    for c in textfieldText {
        if c != " " {
            textFieldHasNonWhitespaceChar = true
            break
        }
    }
    
    // If textfield is empty or only whitespace, make sure only spaces aren't added
    if !textFieldHasNonWhitespaceChar {
        var strippedRepStr = ""
        
        for c in textToAdd {
            if c != " " {
                strippedRepStr.append(c)
            }
        }
        
        // Only spaces being added, so return true
        if (countElements(strippedRepStr) == 0) {
            return true
        }
    }
    
    return false
}

func removeLeadingWhitespaceFromTextField(inout textField: UITextField) {
    let oldText = textField.text as String
    var newText = ""
    var hitNonWhitespaceChar = false
    for c in oldText {
        if hitNonWhitespaceChar {
            newText.append(c)
        }
        else if c != " " {
            hitNonWhitespaceChar = true
            newText.append(c)
        }
    }
    
    textField.text = newText
}

extension UILabel {
    // Adjusts multiline label font size to make text shrink before wrapping onto more than 1 line
    //
    //   Note: Label must have a fixed width. If heightToAdjustFor is unspecified, then the labels
    //         current height is used
    
    //         The idea is to call this after setting the text, with "heightToAdjustFor" being the
    //         height of the label when the text is on X lines. The text is sized to fit on X lines,
    //         and then gets wrapped onto more lines if needed
    func adjustFontSizeToFit(# minFontSize: Int, heightToAdjustFor: CGFloat? = nil) {
        var font = self.font
        let size = self.frame.size
        
        // Calculate the needed font size to fit in the label's height
        // Start at the largest font size, decrease font size by 1 while > minimum font size
        for (var maxSize = self.font.pointSize; maxSize >= self.minimumScaleFactor * self.font.pointSize; maxSize -= 1.0) {
            // New font size
            font = font.fontWithSize(maxSize)
            
            // Make a constraint box using ONLY the FIXED WIDTH of the UILabel, height will be checked later
            let constraintSize = CGSizeMake(size.width, CGFloat(MAXFLOAT))
            
            // Check how tall the label would be with the font
            let textRect = (self.text! as NSString).boundingRectWithSize(constraintSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName : font], context: nil)
            let labelSize = textRect.size
            
            // If specified, use heightToAdjustFor, else the label's current height
            let adjustingHeight = (heightToAdjustFor != nil) ? (heightToAdjustFor) : (size.height)
            
            // If the label fits into the required height, break and use this font size
            if labelSize.height <= adjustingHeight {
                self.font = font
                self.setNeedsLayout()
                break
            }
        }
        
        // Set the font to the minimum size if nothing larger works
        self.font = font.fontWithSize(CGFloat(minFontSize))
        self.setNeedsLayout()
    }
    
    func adjustAttributedFontSizeToFit(heightToAdjustFor: CGFloat? = nil) {
        var font = self.font
        let size = self.frame.size
        
        // Calculate the needed font size to fit in the label's height
        // Start at the largest font size, decrease font size by 1 while > minimum font size
        for (var maxSize = self.font.pointSize; maxSize >= self.minimumScaleFactor * self.font.pointSize; maxSize -= 1.0) {
            // New font size
            font = font.fontWithSize(maxSize)
            
            // Make a constraint box using ONLY the FIXED WIDTH of the UILabel, height will be checked later
            let constraintSize = CGSizeMake(size.width, CGFloat(MAXFLOAT))
            
            // Check how tall the label would be with the font
            let textRect = (self.text! as NSString).boundingRectWithSize(constraintSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName : font], context: nil)
            let labelSize = textRect.size
            
            // If specified, use heightToAdjustFor, else the label's current height
            let adjustingHeight = (heightToAdjustFor != nil) ? (heightToAdjustFor) : (size.height)
            
            // If the label fits into the required height, break and use this font size
            if labelSize.height <= adjustingHeight {
                self.font = font
                self.attributedText =
                    NSAttributedString(
                        string: self.text!,
                        attributes:
                        [
                            NSFontAttributeName: font,
                            NSForegroundColorAttributeName: self.textColor,
                            NSKernAttributeName: 0.2
                        ])
                self.setNeedsLayout()
                break
            }
        }
        
        // Set the font to the minimum size if nothing larger works
        self.font = font
        self.attributedText =
            NSAttributedString(
                string: self.text!,
                attributes:
                [
                    NSFontAttributeName: font,
                    NSForegroundColorAttributeName: self.textColor,
                    NSKernAttributeName: 0.2
                ])
        self.setNeedsLayout()
    }
}

func setTableBackgroundViewWithMessages(tableView: UITableView, mainLine: String, detailLine: String) {
    let f = tableView.frame
    
    let bgView = UIView(frame: f)
    bgView.backgroundColor = UIColor.clearColor()
    tableView.backgroundView = bgView
    
    let messageLabel1 = UILabel()
    messageLabel1.setTranslatesAutoresizingMaskIntoConstraints(false)
    messageLabel1.text = mainLine
    messageLabel1.textColor = UIColor.black()
    messageLabel1.numberOfLines = 0
    messageLabel1.textAlignment = NSTextAlignment.Center
    messageLabel1.font = UIFont.systemFontOfSize(14)
    messageLabel1.sizeToFit()
    bgView.addSubview(messageLabel1)
    
    bgView.addConstraint(NSLayoutConstraint(item: messageLabel1, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: bgView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: -messageLabel1.frame.height / 2))
    bgView.addConstraint(NSLayoutConstraint(item: messageLabel1, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: bgView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
    bgView.addConstraint(NSLayoutConstraint(item: messageLabel1, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: bgView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0))
    
    
    let messageLabel2 = UILabel()
    messageLabel2.setTranslatesAutoresizingMaskIntoConstraints(false)
    messageLabel2.text = detailLine
    messageLabel2.textColor = UIColor.grayDark()
    messageLabel2.numberOfLines = 0
    messageLabel2.textAlignment = NSTextAlignment.Center
    messageLabel2.font = UIFont.systemFontOfSize(11)
    messageLabel2.sizeToFit()
    bgView.addSubview(messageLabel2)
    
    bgView.addConstraint(NSLayoutConstraint(item: messageLabel2, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: messageLabel1, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
    bgView.addConstraint(NSLayoutConstraint(item: messageLabel2, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: bgView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
    bgView.addConstraint(NSLayoutConstraint(item: messageLabel2, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: bgView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0))
}