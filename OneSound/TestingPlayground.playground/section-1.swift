// Playground - noun: a place where people can play

import UIKit

extension String {
    func hasSubstringCaseSensitive(substring: String) -> Bool {
        let substringLength: Int = countElements(substring)
        let stringLength: Int = countElements(self)
        if (substringLength <= stringLength) && (substring != "") {
            for var i = 0; (i + substringLength) <= stringLength; ++i {
                println(self.substringFromIndex(i).substringToIndex(substringLength))
                if (self.substringFromIndex(i).substringToIndex(substringLength)) == substring {
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
        let substringLength: Int = countElements(substringLowercase)
        let stringLength: Int = countElements(stringLowercase)
        if (substringLength <= stringLength) && (substring != "") {
            for var i = 0; (i + substringLength) <= stringLength; ++i {
                println(self.substringFromIndex(i).substringToIndex(substringLength))
                if (stringLowercase.substringFromIndex(i).substringToIndex(substringLength)) == substringLowercase {
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
str.hasSubstringCaseInsensitive("play")
let validCharacters = "abcdefhijklmnopqrstuvwxyz1234567890"
validCharacters.hasSubstringCaseInsensitive("")

for i in 0..<100 {
    println(arc4random() % 6)
}
