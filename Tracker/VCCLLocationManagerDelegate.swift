//
//  VCCLLocationManagerDelegate.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-23.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import MapKit

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    /// <summary>
    ///
    /// </summary>
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {

        if(status == .AuthorizedAlways || status == .AuthorizedWhenInUse) {
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .Follow // zoom to current location and follow
        } else {
            NSLog("LocationManager Status: %@", "\(status.rawValue)")
        }
        
    }
    
    /// <summary>
    ///
    /// </summary>
    func locationManagerDidPauseLocationUpdates(manager: CLLocationManager) {
        print("didPauseLocationUpdates")
    }

    /// <summary>
    ///
    /// </summary>
    func locationManagerDidResumeLocationUpdates(manager: CLLocationManager) {
        print("didResumeLocationUpdates")
    }
    
    /// <summary>
    ///
    /// </summary>
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        NSLog("LocationManager Error: %@", "\(error.localizedDescription)")
    }

    /// <summary>
    ///
    /// </summary>
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if(authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse) {

            
            //print("[didUpdateLocations] \(location.horizontalAccuracy) <\(location.coordinate.latitude),\(location.coordinate.longitude)> \(location.timestamp)")
            self.firebase.storeLocation(location)

            /*
            if (location.horizontalAccuracy <= self.desiredLocationAccuracy) {
                // https://developer.apple.com/library/prerelease/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/LocationBestPractices.html
                // https://github.com/xslim/RouteCompare/blob/master/RouteCompare/Locator.swift
                if (!self.defersLocationUpdates) {

                    self.defersLocationUpdates = true;

                    let distance: CLLocationDistance = self.defersLocationDistance // hike.goal - hike.distance
                    let time: NSTimeInterval = self.defersLocationNextUpdate // nextUpdate.timeIntervalSinceNow()

                    locationManager.allowDeferredLocationUpdatesUntilTraveled(distance, timeout:time)
                    
                    print("[DEFERRED] \(location.horizontalAccuracy) <\(location.coordinate.latitude),\(location.coordinate.longitude)> \(location.timestamp)")

                    self.firebase.storeLocation(location)
                    
                }
            }
            */
            
            /*
            // http://www.raywenderlich.com/92428/background-modes-ios-swift-tutorial
            // can this exist inside authorizationStatus?
            if UIApplication.sharedApplication().applicationState == .Background {
                self.onDidUpdateLocationsWhenInBackground(location)
            }
            */

            /*
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
            */
            
            
        }
        
    }

    /// <summary>
    ///  [DEPRECATED] Helper method: to have background updates of location working
    /// </summary>
    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {

        // Stop deferring updates
        self.defersLocationUpdates = false

        // Adjust for the next goal
        
    }
    
    /// <summary>
    ///  [DEPRECATED] Helper method: to have background updates of location working
    /// </summary>
    func onDidUpdateLocationsWhenInBackground(location: CLLocation) {

        var bgTask = UIBackgroundTaskIdentifier()
        bgTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(bgTask)
        }
        
        //print("App in Background: \(location.coordinate.latitude) \(location.coordinate.longitude)")
        
        if (bgTask != UIBackgroundTaskInvalid)
        {
            UIApplication.sharedApplication().endBackgroundTask(bgTask);
            bgTask = UIBackgroundTaskInvalid;
        }

    }
    
}