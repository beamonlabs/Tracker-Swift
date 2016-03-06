//
//  Firebase.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-19.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import Firebase
import MapKit

protocol FirebaseDBDelegate {
    func didAttachFirebaseEvents()
    func didSetLocation(location: CLLocation)
    func didRemoveUser()
    func willDropPinForUser(user: User)
    func willUpdatePinForUser(user: User)
    func willRemovePinForUser(user: User)
}

class FirebaseDB {
    
    static let sharedInstance = FirebaseDB()

    var ref: Firebase!
    
    var delegate: FirebaseDBDelegate!
    
    var userDefaults = NSUserDefaults.standardUserDefaults()

    var activityIndicatorVisible = UIApplication.sharedApplication().networkActivityIndicatorVisible

    /// <summary>
    ///  Construtor
    /// </summary>
    init() {
        self.ref = Firebase(url: "https://crackling-torch-7934.firebaseio.com/beamontracker/users")
    }
    
    /// <summary>
    ///  Observe events on FirebaseDB
    /// </summary>
    func attachEvents() {
        
        if userDefaults.boolForKey("Authenticated") { //NSLog("%@", "Access granted.")
            
            // just when switch is on for location updates
            if userDefaults.boolForKey("UpdateLocation") {
                
                //self.updateLocationSwitch.on = true
                self.delegate.didAttachFirebaseEvents() // notify observers
                
                // Retrieve new posts as they are added to your database -> includes "all" on start
                ref.observeEventType(.ChildAdded, withBlock: { user in
                    
                    self.handleUser(user)
                    
                    self.activityIndicatorVisible = false
                    
                    }, withCancelBlock: { error in
                        print(error.description)
                        
                })
                
                // when one of the users has updated coordinates
                ref.queryOrderedByKey().observeEventType(.ChildChanged, withBlock: { user in
                    
                    let _user = self.getUserForFDataSnapshot(user)
                    
                    self.delegate.willUpdatePinForUser(_user)

                    self.activityIndicatorVisible = false
                    
                    }, withCancelBlock: { error in
                        print(error.description)
                        
                })
                
                // Retrieve new posts as they are added to your database
                ref.observeEventType(.ChildRemoved, withBlock: { user in
                    
                    let _user = self.getUserForFDataSnapshot(user)
                    
                    self.delegate.willRemovePinForUser(_user)
                    
                    }, withCancelBlock: { error in
                        print(error.description)
                        
                })
                
            }
            
        } else { NSLog("%@", "Access denied.")
            
        }
        
    }
    
    /// <summary>
    ///  Remove all observers for the FirebaseDB reference
    /// </summary>
    func detachEvents() {
        
        ref.removeAllObservers()
        
    }
    
    /// <summary>
    ///  Save the current users location to FirebaseDB
    /// </summary>
    /// <param name="location">The location to store</param>
    func storeLocation(location: CLLocation) {
        
        if userDefaults.boolForKey("Authenticated") && userDefaults.boolForKey("UpdateLocation") {
            
            let deviceName = userDefaults.stringForKey("DeviceName") ?? UIDevice.currentDevice().name
            let fbUserKey = userDefaults.stringForKey("FBUserKey") ?? deviceName
            let fullName = userDefaults.stringForKey("FullName") ?? ""
            let email = userDefaults.stringForKey("Email") ?? ""
            let avatar = userDefaults.stringForKey("Avatar") ?? ""
            
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
            let timestamp = formatter.stringFromDate(location.timestamp)
            
            let userLocation:[String : AnyObject] = [
                "fullName": fullName,
                "email": email,
                "avatar": avatar,
                "timestamp": timestamp,
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude
            ]
            
            self.activityIndicatorVisible = true
            
            // Write data to Firebase
            ref.childByAppendingPath("\(fbUserKey)").setValue(userLocation, withCompletionBlock: {
                (error:NSError?, ref:Firebase!) in
                
                if(error != nil) {
                    print("Data could not be saved.")
                } else {
                    
                    self.delegate.didSetLocation(location)
                    
                    //print("Data saved successfully.")
                }
                self.activityIndicatorVisible = true
                
            })
            
        }
        
    }
    
    /// <summary>
    ///  Remove the current user from FirebaseDB
    /// </summary>
    func remove() {
        
        let deviceName = userDefaults.stringForKey("DeviceName") ?? UIDevice.currentDevice().name
        let fbUserKey = userDefaults.stringForKey("FBUserKey") ?? deviceName
        
        ref.childByAppendingPath("\(fbUserKey)").removeValueWithCompletionBlock({
            (error:NSError?, ref:Firebase!) in
            if(error != nil) {
                //print("Error removing user")
            } else {
                self.delegate.didRemoveUser()
            }
        })
        
    }
    
    /// <summary>
    ///  Helper method: Handle user
    /// </summary>
    /// <param name="o">The user - as FDataSnapshot item</param>
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
            
            self.delegate.willDropPinForUser(user)
            
        } else {
            NSLog("Corrupt FDataSnapshot: %@", user.key)
        }
        
    }
    
    /// <summary>
    ///  Helper method: Returns a user instance from a FirebaseDB user item
    /// </summary>
    /// <param name="o">The user - as FDataSnapshot item</param>
    func getUserForFDataSnapshot(o: FDataSnapshot) -> User {
        
        let key: String = o.key
        
        var location = CLLocation(latitude: 0, longitude: 0)
        
        var fullName: String = key
        
        var email: String = ""

        var timestamp: String = ""

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

        if let _timestamp = o.value["timestamp"] as? String {
            timestamp = _timestamp
        }

        
        return User(key: key, fullName: fullName, email: email, location: location, timestamp: timestamp)
    }
    
}