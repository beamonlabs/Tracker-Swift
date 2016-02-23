//
//  VCMKMapViewDelegate.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-23.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import MapKit

// MARK: - MKMapViewDelegate
extension ViewController: MKMapViewDelegate {

    /// <summary>
    ///
    /// </summary>
    func mapView(mapView: MKMapView, didChangeUserTrackingMode mode: MKUserTrackingMode, animated: Bool) {
        switch mode.rawValue {
        case 0:
            self.setTrackingModeControl.selectedSegmentIndex = -1
        case 1:
            self.setTrackingModeControl.selectedSegmentIndex = 0
        case 2:
            self.setTrackingModeControl.selectedSegmentIndex = 1
        default:
            break
        }
    }
    
    /// <summary>
    ///
    /// </summary>
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is CustomAnnotation {
            
            let identifier = "pin"
            var pin = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            
            if pin == nil {
                pin = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                pin?.image = UIImage(named: "map-pin")
                pin?.canShowCallout = true
                //pin?.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
            } else {
                pin?.annotation = annotation
            }
            
            return pin
        }
        
        return nil
    }
    
    /*
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    
    let annotation = view.annotation as! CustomAnnotation
    if let user = annotation.user {
    print("callout pressed for \(user.fullName), \(user.email)")
    }
    
    }
    */
    
    /*
    // If user selects annotation view for `CustomAnnotation`, then show callout for it. Automatically select
    // that new callout annotation, too.
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
    
    print("didSelectAnnotationView")
    
    }
    */
}