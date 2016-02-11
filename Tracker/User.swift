//
//  User.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-11.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import UIKit
import MapKit

// slidenerd.com/2015/09/07/classes-and-objects-in-swift-2/
// weheartswift.com/object-oriented-programming-swift/
// code.tutsplus.com/tutorials/swift-from-scratch-an-introduction-to-classes-and-structures--cms-23197
// developer.apple.com/library/mac/documentation/Swift/Conceptual/Swift_Programming_Language/Initialization.html
/*
class User {
    
    var key: String? = {
        let deviceName = UIDevice.currentDevice().name
        
        let charSet = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzåäöüßABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖÜ1234567890- ").invertedSet
        let sanitizedKey = deviceName.componentsSeparatedByCharactersInSet(charSet).joinWithSeparator("").stringByReplacingOccurrencesOfString(" ", withString: "-")
        
        return sanitizedKey
    }()
    
    init() {
        self.name = ""
        self.email = ""
        self.location = CLLocation(latitude: 0, longitude: 0)
        self.timestamp = ""
    }

    /*
    init(name: String, email: String, location: CLLocation) {
        self.name = name
        self.email = email
        self.location = location
    }
    */

    let name: String
    let email: String
    let location: CLLocation
    let timestamp: String

}
*/

