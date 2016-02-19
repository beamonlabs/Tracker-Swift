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
            NSLog("LocationManager Status: %@", "\(status.rawValue)")
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        NSLog("LocationManager Error: %@", "\(error.localizedDescription)")
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]

        //print("Location accuracy \(location.horizontalAccuracy), \(location.timestamp.timeIntervalSinceNow)")
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if(authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse) {

            // http://www.raywenderlich.com/92428/background-modes-ios-swift-tutorial
            // can this exist inside authorizationStatus?
            if UIApplication.sharedApplication().applicationState == .Background {
                self.onDidUpdateLocationsWhenInBackground(location)
            }

            //calculation for location selection for pointing annoation
            if let _ = locationLastKnown as CLLocation? { //case if previous location exists
                if locationLastKnown.distanceFromLocation(location) > locationUpdateDistance {
                    locationLastKnown = location
                    // store location in FirebaseDB
                    self.firebase.storeLocation(location)
                }
            } else {
                locationLastKnown = location
                // store location in FirebaseDB
                self.firebase.storeLocation(location)
            }
            
        }
        
    }
    
    // helper method to have background updates of location working
    func onDidUpdateLocationsWhenInBackground(location: CLLocation) {

        var bgTask = UIBackgroundTaskIdentifier()
        bgTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(bgTask)
        }
        
        print("App in Background: \(location.coordinate.latitude) \(location.coordinate.longitude)")
        
        if (bgTask != UIBackgroundTaskInvalid)
        {
            UIApplication.sharedApplication().endBackgroundTask(bgTask);
            bgTask = UIBackgroundTaskInvalid;
        }

    }
    
}