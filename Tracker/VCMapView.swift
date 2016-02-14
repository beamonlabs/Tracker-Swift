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

        /*
        if control == view.rightCalloutAccessoryView {
            print("Disclosure Pressed! \(view.annotation!.subtitle)")
            
            if let cpa = view.annotation as? CustomAnnotation {
                //print("cpa.imageName = \(cpa.imageName)")
                print("\(cpa.title)")
            }
        }
        */

        let annotation = view.annotation as! CustomAnnotation
        if let user = annotation.user {
            print("callout pressed for \(user.fullName), \(user.email)")
        }
        /*
        if (location.title == "Name 1") {
            performSegueWithIdentifier("Segue1", sender: self)
        } else if (location.title == "Name 2")  {
            performSegueWithIdentifier("Segue2", sender: self)
        }
        */
    
    }
    
    //func dropPin(location: CLLocation, title: String, user: FDataSnapshot) {
    func dropPin(user: User) {
        
        /*
        // use this if didset in CustomAnnotation is activated
        let annotation = CustomAnnotation()
        annotation.coordinate = user.location.coordinate
        annotation.title = user.fullName
        annotation.user = user

        mapView.addAnnotation(annotation)

        print("\(user.fullName) @ <\(user.location.coordinate.latitude),\(user.location.coordinate.longitude)>")
        */
        
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(user.location, completionHandler: { (placemarks, error) -> Void in
            if error != nil {
                print("Error: \(error!.localizedDescription)")
                return
            }

            if let placemark = placemarks?.first {

                let annotation = CustomAnnotation()
                annotation.coordinate = user.location.coordinate
                annotation.title = user.fullName
                annotation.subtitle = placemark.name
                annotation.user = user
                
                self.mapView.addAnnotation(annotation)

                print("\(user.fullName) @ \(placemark.name!) <\(user.location.coordinate.latitude),\(user.location.coordinate.longitude)>")
                
            } else {
                print("Error with data")
            }
        })
        
        /*
        dispatch_async(dispatch_get_main_queue()) {
            self.mapView.selectAnnotation(annotation, animated: true)
        }
        */

    }
    
}