//
//  Utils.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-13.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation

/*
extension String {
    
    mutating func replace(string:String, replacement:String) {
        let ranges = self.rangesOfString(string)
        // if the string isn't found return unchanged string
    
        for r in ranges {
            self.replaceRange(r, with: replacement)
        }
    }

}

"ReplaceMe".replace("Me", withString: "You") == "ReplaceYou"
*/
    
class Utils {
    
    class func replaceByDict (var str: String, dict: Dictionary<String, String>) -> String {
        for (key, value) in dict {
            str = str.stringByReplacingOccurrencesOfString(key, withString: value).lowercaseString
        }
        return str
    }
    
    /*
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    */
}