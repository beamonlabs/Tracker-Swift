//
//  VCLocationManager.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-10.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import MapKit

extension ViewController {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if(status == .AuthorizedAlways || status == .AuthorizedWhenInUse) {
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .Follow // zoom to current location and follow
        } else {
            print("LocationManager Status: \(status.rawValue)")
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        print("LocationManager Error: \(error.localizedDescription)")
        
    }
    
    func _locationManagerDidUpdateLocations() {
        
        self.locationManager.startUpdatingLocation()
    
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        
        //print("Location accuracy \(location.horizontalAccuracy)")
        
        /*
        // http://www.raywenderlich.com/92428/background-modes-ios-swift-tutorial
        if UIApplication.sharedApplication().applicationState == .Active {
            //print("Active")
        } else {
            NSLog("App is backgrounded. %@", "OK")
            //NSLog("Background time remaining = %.1f seconds", UIApplication.sharedApplication().backgroundTimeRemaining)
        }
        */

        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if(authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse) {
            
            //calculation for location selection for pointing annoation
            if let _ = locationLastKnown as CLLocation? { //case if previous location exists
                if locationLastKnown.distanceFromLocation(location) > locationUpdateDistance {
                    locationLastKnown = location
                    // store location in FirebaseDB
                    storeLocation(location)
                }
            } else {
                locationLastKnown = location
                // store location in FirebaseDB
                storeLocation(location)
            }
            
        }
        
    }
    
}