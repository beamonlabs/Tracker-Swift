//
//  VCMapView.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-10.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import Foundation
import MapKit

extension ViewController {
    
    // delegate function - hook - override ...
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        /*
        if annotation.isEqual(mapView.userLocation) {
            let identifier = "User"
            
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            
            if annotationView == nil{
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true
                
            } else {
                annotationView!.annotation = annotation
            }
            
            annotationView!.image = UIImage(named: "map-pin")
            
            return annotationView
        }
        */
        
        if annotation is CustomAnnotation {
            let identifier = "pin"
            var pin = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            
            if pin == nil {
                pin = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                pin?.image = UIImage(named: "map-pin")
                pin?.canShowCallout = true
                pin?.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
            } else {
                pin?.annotation = annotation
            }
            
            return pin
        }
        
        return nil
    }
    
    // If user selects annotation view for `CustomAnnotation`, then show callout for it. Automatically select
    // that new callout annotation, too.
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        //print("didSelectAnnotationView")

    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("callout pressed")
    }
    
    func dropPin(location: CLLocation, title: String) {
        
        let annotation = CustomAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = title

        mapView.addAnnotation(annotation)
        
        /*
        dispatch_async(dispatch_get_main_queue()) {
            self.mapView.selectAnnotation(annotation, animated: true)
        }
        */
        
        //print("\(title) @ __ <\(location.coordinate.latitude),\(location.coordinate.longitude)>")
        
    }
    
}