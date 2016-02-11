//
//  VCFirebase.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-11.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import Firebase
import MapKit

extension ViewController {

    
    func storeLocation(location: CLLocation) {
        let charSet = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzåäöüßABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖÜ1234567890- ").invertedSet
        let sanitizedKey = deviceName.componentsSeparatedByCharactersInSet(charSet).joinWithSeparator("").stringByReplacingOccurrencesOfString(" ", withString: "-")
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let timestamp = formatter.stringFromDate(location.timestamp)
        
        let userLocation = [
            "timestamp": timestamp,
            "key": sanitizedKey,
            "name": deviceName,
            "email": "@beamonpeople.se",
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude
        ]
        
        self.activityIndicatorVisible = true
        
        // Write data to Firebase
        firebase.childByAppendingPath("\(sanitizedKey)").setValue(userLocation, withCompletionBlock: {
            (error:NSError?, ref:Firebase!) in
            
            if(error != nil) {
                print("Data could not be saved.")
            } else {
                //print("Data saved successfully.")
            }
            self.activityIndicatorVisible = true
            
        })
    }

    func detachFirebaseEvents() {
        
        firebase.removeAllObservers()
        
    }
    
    func attachFirebaseEvents() {
        
        // just once on app-start: fetch all users locations and set pins
        firebase.observeSingleEventOfType(.Value, withBlock: { users in
            
            //print(users.childrenCount) // I got the expected number of items
            let enumerator = users.children
            while let user = enumerator.nextObject() as? FDataSnapshot {
                self.handleUser(user)
            }
            
            self.activityIndicatorVisible = false

            }, withCancelBlock: { error in
                print(error.description)
        })
        
        // when one of the users has updated coordinates
        firebase.queryOrderedByKey().observeEventType(.ChildChanged, withBlock: { user in
            self.mapView.annotations.forEach {
                var title = user.key
                if let _title = user.value["name"] as? String {
                    title = _title
                }
                if ($0.title!! == title) {
                    //print("Change: should remove pin for '\($0.title!!)'")
                    self.mapView.removeAnnotation($0)
                }
            }
            
            self.handleUser(user)
            
            self.activityIndicatorVisible = false
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        
    }
    
    // Helper method
    func handleUser(o: FDataSnapshot) {
        
        var title = o.key
        if let _title = o.value["name"] as? String {
            title = _title
        }
        
        let latitude = o.value["latitude"] as? Double
        let longitude = o.value["longitude"] as? Double
        if(latitude != nil && longitude != nil) {
            
            let location = CLLocation(latitude: latitude!, longitude: longitude!)
            self.dropPin(location, title: title)
            
        } else {
            NSLog("Corrupt FDataSnapshot: %@", title)
        }
        
    }
    
}