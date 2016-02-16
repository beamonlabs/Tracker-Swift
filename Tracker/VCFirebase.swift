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

            self.handleUser(user)
            self.activityIndicatorVisible = false
            
            }, withCancelBlock: { error in
                print(error.description)

        })
        
        // when one of the users has updated coordinates
        firebase.queryOrderedByKey().observeEventType(.ChildChanged, withBlock: { user in

            self.updateUserPin(user)
            //self.handleUser(user)
            self.activityIndicatorVisible = false
            
            }, withCancelBlock: { error in
                print(error.description)

        })

        // Retrieve new posts as they are added to your database
        firebase.observeEventType(.ChildRemoved, withBlock: { user in
            
            self.removeUserPin(user)
            
            }, withCancelBlock: { error in
                print(error.description)

        })

    }
    
    // Helper method
    func handleUser(o: FDataSnapshot) {
        
        let user = self.getUserForFDataSnapshot(o)
        let latitude = user.location.coordinate.latitude
        let longitude = user.location.coordinate.longitude
        
        // check if the user to handle is the "user" self > don't set pin for
        let isUserSelf : Bool = {
            if let userDefaultsFullName = self.userDefaults.stringForKey("FullName") {
                return (user.fullName == userDefaultsFullName)
            }
            return false
        }()
        
        if(isUserSelf) {
            return
        }
        
        if(latitude != 0 && longitude != 0) {
            
            self.dropPinForUser(user)

        } else {
            NSLog("Corrupt FDataSnapshot: %@", user.key)
        }
        
    }

    func updateUserPin(o: FDataSnapshot) {
        
        for mapViewAnnotation in self.mapView.annotations {
            
            let user = self.getUserForFDataSnapshot(o)
            
            if user.fullName == mapViewAnnotation.title!! {
                let annotation = mapViewAnnotation as! CustomAnnotation
                annotation.coordinate = user.location.coordinate

                print("[UPDATED] \(annotation.title!) @ \(annotation.subtitle!) <\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)>")
            }
            
        }
        
    }
    
    func removeUserPin(o: FDataSnapshot) {
        
        for mapViewAnnotation in self.mapView.annotations {
            
            let user = self.getUserForFDataSnapshot(o)
            
            if user.fullName == mapViewAnnotation.title!! {

                self.mapView.removeAnnotation(mapViewAnnotation)
                
                print("[REMOVED] \(user.fullName)")
                
            }
            
        }
    
    }
    
    func getUserForFDataSnapshot(o: FDataSnapshot) -> User {
        
        let key: String = o.key
        
        var location = CLLocation(latitude: 0, longitude: 0)

        var fullName: String = key
        
        var email: String = ""

        let latitude = o.value["latitude"] as? Double
        
        let longitude = o.value["longitude"] as? Double
        
        
        if let _title = o.value["fullName"] as? String {
            fullName = _title
        }
        
        if let _email = o.value["email"] as? String {
            email = _email
        }
        
        if(latitude != nil && longitude != nil) {
            location = CLLocation(latitude: latitude!, longitude: longitude!)
        }
    
        
        return User(key: key, fullName: fullName, email: email, location: location)
    }
    
}