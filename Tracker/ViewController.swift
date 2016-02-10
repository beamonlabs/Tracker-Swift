//
//  ViewController.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-09.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapLabel: UILabel!
    @IBOutlet weak var setTrackingModeControl: UISegmentedControl!
    
    let deviceName = UIDevice.currentDevice().name // users device name - instead of GoogleAccountAuth

    var locationManager: CLLocationManager!
    
    var previousLocation: CLLocation!
    
    var firebase: Firebase! // storing users/coordinates
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        var alertView:UIAlertView = UIAlertView()
        alertView.title = "Alert!"
        alertView.message = "Message"
        alertView.delegate = self
        alertView.addButtonWithTitle("OK")
        alertView.show()
        */
        
        self.initFirebase()
        self.initMapTracking()
        
        /*
        // http://stackoverflow.com/questions/24056205/how-to-use-background-thread-in-swift
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            print("This is run on the background queue")
        
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print("This is run on the main queue, after the previous code in outer block")
            })
        })
        */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        mapView.mapType = MKMapType(rawValue: 0)! // what does this do?
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // just once on app-start: fetch all users locations and set pins
        firebase.observeSingleEventOfType(.Value, withBlock: { users in
            for user in users.children {
                let latitude = user.value!!["latitude"]
                let longitude = user.value!!["longitude"]
                
                let lat = latitude as? Double
                let long = longitude as? Double
                let title = user.key!!
                
                print("Init: '\(user.key!!)' at <\(latitude!!) \(longitude!!)>")
                self.dropPin(CLLocation(latitude: lat!, longitude: long!), pinTitle: title)
            }
            
            }, withCancelBlock: { error in
                print(error.description)
        })

        // when one of the users has updated coordinates
        firebase.queryOrderedByKey().observeEventType(.ChildChanged, withBlock: { snapshot in
            self.mapView.annotations.forEach {
                if ($0.title!! == snapshot.key) {
                    //print("Change: should remove pin for '\($0.title!!)'")
                    self.mapView.removeAnnotation($0)
                }
            }
            
            let latitude = snapshot.value["latitude"] as? Double
            let longitude = snapshot.value["longitude"] as? Double
            
            //print("Changed: Should drop pin for '\(snapshot.key)' at <\(latitude!),\(longitude!)>")
            self.dropPin(CLLocation(latitude: latitude!, longitude: longitude!), pinTitle: snapshot.key)

            UIApplication.sharedApplication().networkActivityIndicatorVisible = false

            }, withCancelBlock: { error in
                print(error.description)
        })

    }

    override func viewWillDisappear(animated: Bool) {
        firebase.removeAllObservers()
        
        //locationManager.stopUpdatingHeading()
    }
    
    
    
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {

        let authorizationStatus = CLLocationManager.authorizationStatus()
        if(authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse) {
        
            let speed = newLocation.speed
            let speedFomatted = String(format: "%.0f km/h", speed * 3.6)

            // write current location and speed to label
            mapLabel.text = "<\(newLocation.coordinate.latitude),\(newLocation.coordinate.longitude)>\nspeed: \(speedFomatted)"

            
            //calculation for location selection for pointing annoation
            if let _ = previousLocation as CLLocation? { //case if previous location exists
                if previousLocation.distanceFromLocation(newLocation) > 250 {
                    // store location at Firebase
                    storeLocation(newLocation)

                    previousLocation = newLocation
                }
            } else {
                // store location at Firebase
                storeLocation(newLocation)
                
                previousLocation = newLocation
            }
            
        }
        
        /*
        // http://www.raywenderlich.com/92428/background-modes-ios-swift-tutorial
        if UIApplication.sharedApplication().applicationState == .Active {
            print("Active")
        } else {
            NSLog("App is backgrounded. %@", "OK")
        }
        */
        
    }
    
    
    func zoomToCurrentLocation() {
        
        let userLocation:MKUserLocation = self.mapView.userLocation
        
        let spanX:Double = 0.007
        let spanY:Double = 0.007
        let newRegion = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        
        
        // center and update location on map
        mapView.setRegion(newRegion, animated: true)

    }
    
    func dropPin(location: CLLocation, pinTitle: String) {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemark, error) -> Void in
            if error != nil {
                print("Error: \(error!.localizedDescription)")
                return
            }
            if placemark!.count > 0 {
                let pm = placemark![0] as CLPlacemark

                var addressDictionary = pm.addressDictionary;
                annotation.title = pinTitle
                annotation.subtitle = addressDictionary!["Name"] as? String
                
                self.mapView.addAnnotation(annotation)
                print("Dropped pin for '\(annotation.title!)' at '\(annotation.subtitle!)' <\(location.coordinate.latitude),\(location.coordinate.longitude)>")
                
            } else {
                print("Error with data")
            }
        })
        
    }
    
    
    
    
    
    
    // Setup Firebase
    func initFirebase() {
        firebase = Firebase(url: "https://crackling-torch-7934.firebaseio.com/beamontracker/users")
    }

    func storeLocation(locationToStore: CLLocation) {
        let userLocation = ["latitude": locationToStore.coordinate.latitude, "longitude": locationToStore.coordinate.longitude]
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // Write data to Firebase
        firebase.childByAppendingPath("\(deviceName)").setValue(userLocation)
    }

    //Setup Location Manager and MapView
    func initMapTracking() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        locationManager.allowsBackgroundLocationUpdates = true // this is needed for ios9 to get the location even when it's backgrounded
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        mapView.delegate = self
        mapView.mapType = .Standard
        mapView.showsUserLocation = true
        
        // exists in didChangeAuth-Callback from locationManager to prevent Errors
        //mapView.userTrackingMode = .Follow // zoom to current location and follow
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if(status == .AuthorizedAlways || status == .AuthorizedWhenInUse) {
            mapView.userTrackingMode = .Follow // zoom to current location and follow
        } else {
            print("LocationManager Status: \(status.rawValue)")
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("LocationManager Error: \(error.localizedDescription)")
    }
    
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
    
    @IBAction func setTrackingMode(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.mapView.userTrackingMode = .Follow
        case 1:
            self.mapView.userTrackingMode = .FollowWithHeading
        default:
            break
        }
    }

    @IBAction func setMapType(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.mapView.mapType = .Standard
        case 1:
            self.mapView.mapType = .Satellite
        default:
            break
        }
    }
    
}

