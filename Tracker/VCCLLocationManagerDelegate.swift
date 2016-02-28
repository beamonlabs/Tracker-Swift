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
    ///  Delegate when the auth-status has changed - location updates (not) accepted from user
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
    ///  Delegate when an error occurred for location manager
    /// </summary>
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        NSLog("LocationManager Error: %@", "\(error.localizedDescription)")
    }

    /// <summary>
    ///  Delegate when location changed (call based on filter, type etc.)
    /// </summary>
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if(authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse) {
            self.firebase.storeLocation(location)
        }
        
    }
    
}