//
//  Artwork.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-10.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import MapKit

class CustomAnnotation : MKPointAnnotation {
    /*
    static let geoCoder: CLGeocoder = CLGeocoder()

    // if we set the coordinate, geocode it
    // ISSUE: not working always/at first time after opening app ???
    override var coordinate: CLLocationCoordinate2D {
        didSet {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CustomAnnotation.geoCoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    self.subtitle = placemark.name
                }
            }
        }
    }
    */
    
    var user: User?

}