//
//  OneSound Colors.swift
//  OneSound
//
//  Created by adam on 7/14/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import Foundation

enum UserColors: String {
    case Green = "g"
    case Turquoise = "t"
    case Purple = "p"
    case Red = "r"
    case Orange = "o"
    case Yellow = "y"
    
    func UserColorsToOneSoundColorOption() -> OneSoundColorOption {
        switch self {
        case .Green:
            return OneSoundColorOption.Green
        case .Turquoise:
            return OneSoundColorOption.Turquiose
        case .Purple:
            return OneSoundColorOption.Purple
        case .Red:
            return OneSoundColorOption.Red
        case .Orange:
            return OneSoundColorOption.Orange
        case .Yellow:
            return OneSoundColorOption.Yellow
        }
    }
}

enum OneSoundColorOption: String {
    case Random = "Random"
    case Green = "Green"
    case Turquiose = "Turquoise"
    case Purple = "Purple"
    case Red = "Red"
    case Orange = "Orange"
    case Yellow = "Yellow"
    
    func OneSoundColorOptionToUserColor() -> UserColors {
        switch self {
        case .Random:
            return LocalUser.sharedUser.randomColor()
        case .Green:
            return UserColors.Green
        case .Turquiose:
            return UserColors.Turquoise
        case .Purple:
            return UserColors.Purple
        case .Red:
            return UserColors.Red
        case .Orange:
            return UserColors.Orange
        case .Yellow:
            return UserColors.Yellow
        }
    }
}

extension UIColor {
    
    class func black() -> UIColor {
        return UIColor.colorWithHexString("000000")
    }
    
    class func grayDark() -> UIColor {
        return UIColor.colorWithHexString("969696")
    }
    
    class func grayMid() -> UIColor {
        return UIColor.colorWithHexString("DCDCDC")
    }
    
    class func grayLight() -> UIColor {
        return UIColor.colorWithHexString("F5F5F5")
    }
    
    class func white() -> UIColor {
        return UIColor.colorWithHexString("FFFFFF")
    }
    
    class func blue() -> UIColor {
        return UIColor.colorWithHexString("32C8F4")
    }
    
    class func purple() -> UIColor {
        return UIColor.colorWithHexString("BD10E0")
    }
    
    class func turquoise() -> UIColor {
        return UIColor.colorWithHexString("00D7AA")
    }
    
    class func yellow() -> UIColor {
        return UIColor.colorWithHexString("EAE10A")
    }
    
    class func red() -> UIColor {
        return UIColor.colorWithHexString("FF415E")
    }
    
    class func orange() -> UIColor {
        return UIColor.colorWithHexString("FF972D")
    }
    
    class func green() -> UIColor {
        return UIColor.colorWithHexString("57E54E")
    }
}