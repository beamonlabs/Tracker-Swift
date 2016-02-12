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
        
        if let annotation = annotation as? MyAnnotation {
            let identifier = "pin"
            var view: MKAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.enabled = true
                view.canShowCallout = true
                //view.image = UIImage(named: "map-pin")
                //view.calloutOffset = CGPoint(x: -5, y: 5)
                view.leftCalloutAccessoryView = UIImageView(image: UIImage(named: "map-pin"))
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
                //view.detailCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
            }
            
            view.enabled = true

            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("callout pressed")
    }
    
    
    
    
    func dropPin(location: CLLocation, title: String) {
        
        //let annotation = MKPointAnnotation()
        //annotation.coordinate = location.coordinate
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemark, error) -> Void in
            if error != nil {
                print("Error: \(error!.localizedDescription)")
                return
            }
            if placemark!.count > 0 {
                let pm = placemark![0] as CLPlacemark
                
                var addressDictionary = pm.addressDictionary;
                let locationName = addressDictionary!["Name"] as? String
                
                /*
                annotation.title = pinTitle
                annotation.subtitle = addressDictionary!["Name"] as? String
                
                self.mapView.addAnnotation(annotation)
                print("Dropped pin for '\(annotation.title!)' at '\(annotation.subtitle!)' <\(location.coordinate.latitude),\(location.coordinate.longitude)>")
                */
                
                let myAnnotation = MyAnnotation(title: title, locationName: locationName!, coordinate: location.coordinate)
                self.mapView.addAnnotation(myAnnotation)
                
                print("\(title) @ \(locationName!) <\(location.coordinate.latitude),\(location.coordinate.longitude)>")
                
                
            } else {
                print("Error with data")
            }
        })
        
    }
    
    /*
    func zoomToCurrentLocation() {
    
        let userLocation:MKUserLocation = self.mapView.userLocation
        
        let spanX:Double = 0.007
        let spanY:Double = 0.007
        let newRegion = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        
        
        // center and update location on map
        mapView.setRegion(newRegion, animated: true)
        
    }
    */
    
}