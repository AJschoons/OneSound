// Playground - noun: a place where people can play

import UIKit

extension String {
    func hasSubstringCaseSensitive(substring: String) -> Bool {
        let substringLength: Int = countElements(substring)
        let stringLength: Int = countElements(self)
        if (substringLength <= stringLength) && (substring != "") {
            for var i = 0; (i + substringLength) <= stringLength; ++i {
                let indexToStartAt = advance(self.startIndex, i)
                let indexToEndAt = advance(indexToStartAt, substringLength)
                let range = indexToStartAt..<indexToEndAt
                println(self[range])
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
                println(stringLowercase[range])
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


var str = "HelloPlayground"
str.hasSubstringCaseSensitive("play")
let validCharacters = "abcdefhijklmnopqrstuvwxyz1234567890"
validCharacters.hasSubstringCaseInsensitive("")

//for i in 0..<100 {
//    println(arc4random() % 6)
//}

func firstThreeIntegersOfNumberFromBase(num: Int) {
}

let base = 1000
1001 / base
1010 / base
1200 / base
12345 / base
123456 / base

let base2 = 1000000
1000000 / base2
1200000 / base2




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
        return formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: posNum, baseOfNumber: 1000, "k")
    case 1000000...999999999:
        return formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: posNum, baseOfNumber: 1000000, "M")
    default:
        return "MAX"
    }
}

formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: -1, baseOfNumber: 1, "")
formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: 0, baseOfNumber: 1, "")
formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: 1, baseOfNumber: 1, "")
formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: 12, baseOfNumber: 1, "")
formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: 123, baseOfNumber: 1, "")
formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: 1099, baseOfNumber: 1000, "k")
formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: 1234, baseOfNumber: 1000, "k")
formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: 12345, baseOfNumber: 1000, "k")
formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: 123456, baseOfNumber: 1000, "k")
formatFirstThreeDigitsOfIntFromBaseWithPostfix(numberToFormat: 1234567, baseOfNumber: 1000000, "k")

intFormattedToShortStringForDisplay(-1)
intFormattedToShortStringForDisplay(0)
intFormattedToShortStringForDisplay(1)
intFormattedToShortStringForDisplay(12)
intFormattedToShortStringForDisplay(123)
intFormattedToShortStringForDisplay(1000)
intFormattedToShortStringForDisplay(1234)
intFormattedToShortStringForDisplay(123456)
intFormattedToShortStringForDisplay(1000000)
intFormattedToShortStringForDisplay(1234567)
intFormattedToShortStringForDisplay(12345678)
intFormattedToShortStringForDisplay(123456789)
intFormattedToShortStringForDisplay(1234567890)


// Testing networking recursion
let f: ()->() = { println("doing failure code") }
let s: ()->() = { println("doing success code") }

func actualRequestThang(shouldSucceed: Bool, success: ()->(), failure: ()->()) {
    if shouldSucceed {
        success()
    } else {
        failure()
    }
}

func someNetworkingReqeustExample(success: ()->(), failure: ()->(), numOfAttemptsToMake: Int = 3) {
    let fWithSucceess: ()->() = {
        println("trying to execute request")
        if numOfAttemptsToMake > 0 {
            someNetworkingReqeustExample(success, failure, numOfAttemptsToMake: (numOfAttemptsToMake - 1))
        } else {
            failure()
        }
    }
    
    actualRequestThang(numOfAttemptsToMake == 1, success, fWithSucceess)
}

someNetworkingReqeustExample(s, f)

let SCstr = "https://i1.sndcdn.com/artworks-000075859755-jcijgn-large.jpg?e76cf77"

extension String {
    func replaceSubstringWithString(oldSubstring: String, newSubstring: String) -> String {
        let oldSubstrL: Int = countElements(oldSubstring)
        let stringL: Int = countElements(self)
        if (oldSubstrL <= stringL) && (oldSubstring != "") {
            for var i = 0; (i + oldSubstrL) <= stringL; ++i {
                let indexToStartAt = advance(self.startIndex, i)
                let indexToEndAt = advance(indexToStartAt, oldSubstrL)
                let substringRange = indexToStartAt..<indexToEndAt
                println(self[substringRange])
                if self[substringRange] == oldSubstring {
                    let firstPartOfStringRange = self.startIndex..<indexToStartAt
                    let lastPartOfStringRange = indexToEndAt..<self.endIndex
                    //println()
                    //println(self[firstPartOfStringRange])
                    //println(self[substringRange])
                    //println(self[lastPartOfStringRange])
                    //println()
                    return self[firstPartOfStringRange] + newSubstring + self[lastPartOfStringRange]
                }
            }
        }
        return self
    }
}

SCstr.replaceSubstringWithString("-large.jpg", newSubstring: "-t500x500.jpg")

func replaceSpacesWithASCIISpaceCodeForURL(urlString: String) -> String {
    //let newURLString = urlString.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: nil, range: nil)
    let newURLString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
    return newURLString
}

replaceSpacesWithASCIISpaceCodeForURL("kanye west")

