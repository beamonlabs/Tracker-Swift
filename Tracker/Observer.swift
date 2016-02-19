//
//  Observer.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-19.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation

extension ViewController {

    // Callback:
    func applicationDidBecomeActiveNotification() {
        // Handle application did become active notification event.

        self.firebase.attachEvents()

    }
    
    // Callback:
    func applicationWillResignActiveNotification() {
        // Handle application will resign notification event.
        
        self.firebase.detachEvents()
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        
    }

}