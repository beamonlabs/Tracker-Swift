//
//  Artwork.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-10.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import MapKit

/*
class MyAnnotation: NSObject, MKAnnotation {
    
    let title: String?
    let locationName: String
    dynamic var coordinate: CLLocationCoordinate2D // http://stackoverflow.com/a/29776550

    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        
        super.init()
    }

    var subtitle: String? {
        return locationName
    }

}
*/

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