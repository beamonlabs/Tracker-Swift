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
    @IBOutlet weak var setTrackingModeControl: UISegmentedControl!
    
    var firebase: Firebase! // storing users/coordinates

    var locationUpdateDelay:Double = 15.0
    
    var locationUpdateDistance:Double = 300
    
    var locationLastKnown: CLLocation!
    
    lazy var locationManager: CLLocationManager! = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters //kCLLocationAccuracyBest
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true // this is needed for ios9 to get the location even when it's backgrounded
        manager.distanceFilter = self.locationUpdateDistance
        manager.requestAlwaysAuthorization()

        return manager
    }()

    let deviceName = UIDevice.currentDevice().name // users device name - instead of GoogleAccountAuth
    
    var activityIndicatorVisible = UIApplication.sharedApplication().networkActivityIndicatorVisible


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firebase = Firebase(url: "https://crackling-torch-7934.firebaseio.com/beamontracker/users")

        locationManager.startUpdatingLocation() // startMonitoringSignificantLocationChanges()
        
        mapView.delegate = self
        mapView.mapType = .Standard
        mapView.showsUserLocation = true

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
        
        self.attachFirebaseEvents()

    }

    override func viewWillDisappear(animated: Bool) {
        
        self.detachFirebaseEvents()
        
        //locationManager.stopUpdatingHeading()
        
    }
    
    
    
    /*
    @IBAction func alertBtn(sender: UIButton) {
        
        let alert = UIAlertController(title: "New Name",
            message: "Add a new name",
            preferredStyle: .Alert)
        
        let saveAction = UIAlertAction(title: "Save",
            style: .Default,
            handler: { (action:UIAlertAction) -> Void in
                
                let textField = alert.textFields!.first
                print("\(textField!.text!)")
                //self.names.append(textField!.text!)
                //self.tableView.reloadData()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel",
            style: .Default) { (action: UIAlertAction) -> Void in
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField) -> Void in
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert,
            animated: true,
            completion: nil)
    }
    */
    
    

    
    

    
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