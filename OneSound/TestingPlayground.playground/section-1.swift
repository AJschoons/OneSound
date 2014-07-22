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

for i in 0..<100 {
    println(arc4random() % 6)
}
