//
//  Artwork.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-10.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import MapKit

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