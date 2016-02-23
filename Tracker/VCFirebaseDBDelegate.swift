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
        
    }
    
    /// <summary>
    ///  When to drop a pin for a user
    /// </summary>
    /// <param name="user">The user</param>
    func willDropPinForUser(user: User) {
        
        self.dropPinForUser(user)
        
        //self.users.append(user)
        //print("\(self.users)")
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
                
            }
        }
        
        /*
        dispatch_async(dispatch_get_main_queue()) {
        self.mapView.selectAnnotation(annotation, animated: true)
        }
        */
        
    }
    
}