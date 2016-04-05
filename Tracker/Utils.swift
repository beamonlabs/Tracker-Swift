//
//  Utils.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-13.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation

extension String {
    func replace(target: String, withString: String) -> String {
        return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
}

extension String {

    func capitalize() -> String {
        //break it into an array by delimiting the sentence using a space
        let breakupSentence = self.componentsSeparatedByString(".")
        var newSentence = ""
        
        //Loop the array and concatinate the capitalized word into a variable.
        for wordInSentence in breakupSentence {
            newSentence = "\(newSentence) \(wordInSentence.capitalizedString)"
        }
        
        return newSentence.trim()
    }
}

extension String {
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}