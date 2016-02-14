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
        
        if userDefaults.boolForKey("Authenticated") && userDefaults.boolForKey("UpdateLocation") {
            
            let deviceName = userDefaults.stringForKey("DeviceName") ?? UIDevice.currentDevice().name
            let fbUserKey = userDefaults.stringForKey("FBUserKey") ?? deviceName
            let fullName = userDefaults.stringForKey("FullName") ?? ""
            let email = userDefaults.stringForKey("Email") ?? ""
            
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
            let timestamp = formatter.stringFromDate(location.timestamp)
            
            let userLocation:[String : AnyObject] = [
                "fullName": fullName,
                "email": email,
                "timestamp": timestamp,
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude
            ]
            
            self.activityIndicatorVisible = true
            
            // Write data to Firebase
            firebase.childByAppendingPath("\(fbUserKey)").setValue(userLocation, withCompletionBlock: {
                (error:NSError?, ref:Firebase!) in
                
                if(error != nil) {
                    print("Data could not be saved.")
                } else {
                    //print("Data saved successfully.")
                }
                self.activityIndicatorVisible = true
                
            })
            
        }

    }

    func detachFirebaseEvents() {
        
        firebase.removeAllObservers()
        
    }
    
    func removeFromFirebase() {

        let deviceName = userDefaults.stringForKey("DeviceName") ?? UIDevice.currentDevice().name
        let fbUserKey = userDefaults.stringForKey("FBUserKey") ?? deviceName

        firebase.childByAppendingPath("\(fbUserKey)").removeValueWithCompletionBlock({
            (error:NSError?, ref:Firebase!) in
            if(error != nil) {
                print("Data removed")
            } else {
                //print("Data saved successfully.")
            }
        })

    }
    
    
    func attachFirebaseEvents() {
        
        // Retrieve new posts as they are added to your database -> includes "all" on start
        firebase.observeEventType(.ChildAdded, withBlock: { user in
            //print("ChildAdded \(user.value.objectForKey("fullName"))")

            self.handleUser(user)
            self.activityIndicatorVisible = false
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        // when one of the users has updated coordinates
        firebase.queryOrderedByKey().observeEventType(.ChildChanged, withBlock: { user in
            //print("ChildChanged \(user.value.objectForKey("fullName"))")

            self.removeUserPin(user)
            self.handleUser(user)
            self.activityIndicatorVisible = false
            
            }, withCancelBlock: { error in
                print(error.description)
        })

        // Retrieve new posts as they are added to your database
        firebase.observeEventType(.ChildRemoved, withBlock: { user in
            //print("ChildRemoved \(user.value.objectForKey("fullName"))")
            
            self.removeUserPin(user)
            
            }, withCancelBlock: { error in
                print(error.description)
        })

    }
    
    // Helper method
    func handleUser(o: FDataSnapshot) {
        
        var title = o.key
        if let _title = o.value["fullName"] as? String {
            title = _title
        }
        let email = o.value["email"] as? String
        
        let latitude = o.value["latitude"] as? Double
        let longitude = o.value["longitude"] as? Double
        if(latitude != nil && longitude != nil) {
            
            let location = CLLocation(latitude: latitude!, longitude: longitude!)

            // instantiate user
            let user = User(key: o.key, fullName: title, email: email!, location: location)
            //self.dropPin(location, title: title, user: o)
            self.dropPin(user)
            
        } else {
            NSLog("Corrupt FDataSnapshot: %@", title)
        }
        
    }
    
    func removeUserPin(o: FDataSnapshot) {
        
        self.mapView.annotations.forEach {
            var title = o.key
            if let _title = o.value["fullName"] as? String {
                title = _title
            }
            if ($0.title!! == title) {
                //print("Change: should remove pin for '\($0.title!!)'")
                self.mapView.removeAnnotation($0)
            }
        }
    
    }
    
}