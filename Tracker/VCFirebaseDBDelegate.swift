//
//  VCFirebaseDBDelegate.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-23.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation

// MARK: - FirebaseDBDelegate
extension ViewController: FirebaseDBDelegate {
    
    /// <summary>
    ///  When firebase events successfully attached
    /// </summary>
    func didAttachFirebaseEvents() {
        //self.updateLocationSwitch.on = true
    }
    
    /// <summary>
    ///  When to store the last "stored" location
    /// </summary>
    /// <param name="location">The location to store</param>
    func didSetLocation(location: CLLocation) {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "d/M yyyy, hh:mm"
        let date = dateFormatter.stringFromDate(location.timestamp)
        
        self.locationMeta = ["title": "\(date)", "location": "<\(location.coordinate.latitude), \(location.coordinate.latitude)>"]
        
        let timeFormatter = NSDateFormatter()
        timeFormatter.dateFormat = "hh:mm"
        let formattedTime = NSString(format: "Position uppdaterades kl %@", timeFormatter.stringFromDate(location.timestamp)) as String
        self.locationUpdateLabel.text = formattedTime
        
    }
    
    /// <summary>
    ///  When the current user is removed from firebase
    /// </summary>
    func didRemoveUser() {
        self.locationUpdateLabel.text = ""
        self.annotationCountLabel.text = ""
    }
    
    /// <summary>
    ///  When to drop a pin for a user
    /// </summary>
    /// <param name="user">The user</param>
    func willDropPinForUser(user: User) {
        
        self.dropPinForUser(user)
        
        self.addToUsers(user)

    }
    
    /// <summary>
    ///  When to update the location name for a user
    /// </summary>
    /// <param name="user">The user</param>
    func willUpdatePinForUser(user: User) {
        for mapViewAnnotation in self.mapView.annotations {
            
            if user.fullName == mapViewAnnotation.title!! {
                let geoCoder = CLGeocoder()
                
                let annotation = mapViewAnnotation as! CustomAnnotation
                annotation.coordinate = user.location.coordinate
                
                // reverse geocode
                let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                geoCoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let placemark = placemarks?.first {
                        annotation.subtitle = placemark.name
                    }
                }
                
                print("[UPDATED] \(annotation.title!) @ \(annotation.subtitle!) <\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)>")
                
                // update locationName in global users variable and reload table
                user.setLocationName(annotation.subtitle!)
                self.tableView.reloadData()
            }
            
        }
    }
    
    /// <summary>
    ///  When to remove a pin for a specific user
    /// </summary>
    /// <param name="user">The user</param>
    func willRemovePinForUser(user: User) {
        for mapViewAnnotation in self.mapView.annotations {
            
            if user.fullName == mapViewAnnotation.title!! {
                
                self.mapView.removeAnnotation(mapViewAnnotation)
                
                self.removeFromUsers(user)

                print("[REMOVED] \(user.fullName)")
                
            }
            
        }
    }
    
    
    
    /// <summary>
    ///  Helper method: drop a pin for a specific user
    /// </summary>
    /// <param name="user">The user</param>
    func dropPinForUser(user: User) {
        
        let geoCoder = CLGeocoder()
        let userLocation = user.location.coordinate
        let location = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        // reverse geocode
        geoCoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                
                let annotation = CustomAnnotation()
                annotation.coordinate = user.location.coordinate
                annotation.title = user.fullName
                annotation.subtitle = placemark.name
                annotation.user = user
                self.mapView.addAnnotation(annotation)
                
                print("[PINNED] \(annotation.title!) @ \(annotation.subtitle!) <\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)>")

                // update locationName in global users variable and reload table
                user.setLocationName(annotation.subtitle!)
                self.tableView.reloadData()
            }
        }
        
        /*
        dispatch_async(dispatch_get_main_queue()) {
        self.mapView.selectAnnotation(annotation, animated: true)
        }
        */
        
    }
    
    /// <summary>
    ///  Helper method: add a user to the global users array
    /// </summary>
    /// <param name="user">The user</param>
    func addToUsers(user: User) {
        
        let isContained = self.users.contains({ element in
            return (element.email == user.email)
        })
        
        if(!isContained) {
            self.users.append(user)

            self.data.append(user)
            
            self.tableView.reloadData()
        }
        
        self.annotationCountLabel.text = String(self.users.count) + self.annotationCountLabelSuffix
        
    }

    /// <summary>
    ///  Helper method: remove a user from the global users array
    /// </summary>
    /// <param name="user">The user</param>
    func removeFromUsers(user: User) {

        let isContained = self.users.contains({ element in
            return (element.email == user.email)
        })
        
        if(isContained) {
            
            for (index, value) in self.users.enumerate() {
                if value.email == user.email {
                    self.users.removeAtIndex(index)
                }
            }
            
            self.annotationCountLabel.text = String(self.users.count) + self.annotationCountLabelSuffix
            
        }

    }

}