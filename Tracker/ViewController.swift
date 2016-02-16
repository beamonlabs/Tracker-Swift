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
    
    @IBOutlet weak var updateLocationSwitch: UISwitch!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var setTrackingModeControl: UISegmentedControl!
    @IBOutlet weak var userDetailButton: UIButton!
    

    var firebase: Firebase! // storing users/coordinates

    var locationUpdateDistance:Double = 300
    
    var locationLastKnown: CLLocation!

    
    lazy var locationManager: CLLocationManager! = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters //kCLLocationAccuracyBest
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true // this is needed for ios9 to get the location even when it's backgrounded
        manager.distanceFilter = self.locationUpdateDistance
        manager.requestAlwaysAuthorization()
        manager.pausesLocationUpdatesAutomatically = false // not really documentated - but needed?

        return manager
    }()
    //var locationManager = CLLocationManager() // should take/share settings from AppDelegate

    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    var activityIndicatorVisible = UIApplication.sharedApplication().networkActivityIndicatorVisible


    
    override func viewDidLoad() {
        super.viewDidLoad()

        firebase = Firebase(url: "https://crackling-torch-7934.firebaseio.com/beamontracker/users")
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation() // startMonitoringSignificantLocationChanges()
        
        mapView.delegate = self
        mapView.mapType = .Standard

        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onApplicationDidEnterBackground:"), name:UIApplicationDidEnterBackgroundNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()

        mapView.mapType = MKMapType(rawValue: 0)! // what does this do?
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if userDefaults.boolForKey("Authenticated") { //NSLog("%@", "Access granted.")
            
            // just when switch is on for location updates
            if userDefaults.boolForKey("UpdateLocation") {
                self.updateLocationSwitch.on = true
                self.attachFirebaseEvents()
            }

        } else { NSLog("%@", "Access denied.")
            
        }

    }

    override func viewWillDisappear(animated: Bool) {
        
        self.detachFirebaseEvents()
        
    }
    
    
    
    
    func yourMethodName() {
        print("called from AppDelegate")
    }
    
    /*
    func onApplicationDidEnterBackground(notification : NSNotification) {
        print("onApplicationDidEnterBackground method called")
        
        //You may call your action method here, when the application did enter background.
        //ie., self.pauseTimer() in your case.
    
    }
    */
    
    
    
    
    /*
    func onAuthenticate() {
    
    let alertController = UIAlertController(title: "UIAlertController", message: "UIAlertController", preferredStyle: .ActionSheet)
    
    let ok = UIAlertAction(title: "Ok", style: .Default, handler: { (action) -> Void in
    print("Ok Button Pressed")
    })
    let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) -> Void in
    print("Cancel Button Pressed")
    })
    let  delete = UIAlertAction(title: "Delete", style: .Destructive) { (action) -> Void in
    print("Delete Button Pressed")
    }
    
    alertController.addAction(ok)
    alertController.addAction(cancel)
    alertController.addAction(delete)
    
    presentViewController(alertController, animated: true, completion: nil)
    
    }
    */
    
    
    func requestUserAuthentication() {
        
        let alert = UIAlertController(title: "Användarinformation", message: nil, preferredStyle: .Alert)
        
        let saveAction = UIAlertAction(title: "Spara",
            style: .Default) { (action: UIAlertAction!) -> Void in
                
                if let fullName = ((alert.textFields?.first)! as UITextField).text {
                    self.userDefaults.setValue(fullName, forKey: "FullName")
                }
                
                if let email = ((alert.textFields?.last)! as UITextField).text {
                    // prepare Firebase user key by processing email address
                    let dictKeyFromEmail : Dictionary<String, String> = [
                        "@beamonpeople.se": "",
                        ".": " "
                    ]
                    let fbUserKey = Utils.replaceByDict(email, dict: dictKeyFromEmail)
                    
                    self.userDefaults.setValue(email, forKey: "Email")
                    self.userDefaults.setValue(fbUserKey, forKey: "FBUserKey")
                }
                
                self.userDefaults.setBool(true, forKey: "Authenticated")
                
                self.userDetailButton.hidden = false
                
                if self.updateLocationSwitch.on {
                    self.userDefaults.setBool(true, forKey: "UpdateLocation")

                    // force setting
                    let userLocation = self.mapView.userLocation.location
                    self.storeLocation(userLocation!)
                    
                    self.attachFirebaseEvents()
                }
                
        }
        saveAction.enabled = false
        
        let cancelAction = UIAlertAction(title: "Avbryt",
            style: .Default) { (action: UIAlertAction!) -> Void in
                
                // if already authenticated, don't reset switch state
                if !self.userDefaults.boolForKey("Authenticated") {
                    // reset switch to "off"
                    self.updateLocationSwitch.on = false
                }
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (tfFullName:UITextField) in
            tfFullName.text = self.userDefaults.stringForKey("FullName") ?? ""
            tfFullName.placeholder = "Förnamn Efternamn"
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (tfEmail:UITextField) in
            tfEmail.text = self.userDefaults.stringForKey("Email") ?? ""
            tfEmail.placeholder = "fornamn.efternamn@beamonpeople.se"
            tfEmail.keyboardType = .EmailAddress
        }
        
        // adding the notification observer here
        NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object:alert.textFields?[0], queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            let tfFullName = (alert.textFields?[0])! as UITextField
            let tfEmail = alert.textFields![1] as UITextField
            saveAction.enabled = self.isValidEmail(tfEmail.text!) &&  !tfFullName.text!.isEmpty
        }
        NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object:alert.textFields?[1], queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            let tfFullName = alert.textFields![0] as UITextField
            let tfEmail = alert.textFields![1] as UITextField
            saveAction.enabled = self.isValidEmail(tfEmail.text!) &&  !tfFullName.text!.isEmpty
        }
        
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        // .Default action should be bold by "design" - but needs explicit def in iOS 9
        alert.preferredAction = alert.actions[1]
        
        self.presentViewController(alert, animated: true, completion: nil)
        
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

    /*
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
    */

    // http://www.ioscreator.com/tutorials/uiswitch-tutorial-in-ios8-with-swift
    @IBAction func onUpdateLocationSwitchChange(sender: UISwitch) {
        if(updateLocationSwitch.on) {
            
            if userDefaults.boolForKey("Authenticated") { //NSLog("%@", "Access granted.")
                self.userDefaults.setBool(true, forKey: "UpdateLocation")
                
                self.locationManager.startUpdatingLocation()
                self.mapView.userTrackingMode = .Follow // zoom to current location and follow
                
                self.attachFirebaseEvents()

                // force setting
                let userLocation = self.mapView.userLocation.location
                self.storeLocation(userLocation!)
                
            } else {
                self.requestUserAuthentication()
            }

        } else {

            self.userDefaults.setBool(false, forKey: "UpdateLocation")
            
            self.locationManager.stopUpdatingLocation()
            self.mapView.removeAnnotations(self.mapView.annotations)

            self.detachFirebaseEvents()
            
            self.removeFromFirebase() // remove the user from firebase - security reasons
        
        }
    }
    

    @IBAction func onInfoButton(sender: UIButton) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let userDetails = UIAlertAction(title: "Användarinformation", style: .Default, handler: { (action) -> Void in
            self.requestUserAuthentication()
        })
        
        let mapTypeDefault = UIAlertAction(title: "Karta", style: .Default, handler: { (action) -> Void in
            self.mapView.mapType = .Standard
        })
        
        let mapTypeSatellite = UIAlertAction(title: "Satellit", style: .Default, handler: { (action) -> Void in
            self.mapView.mapType = .Satellite
        })
        
        let cancel = UIAlertAction(title: "Avbryt", style: .Cancel, handler: { (action) -> Void in
            // TODO
        })
        
        
        if userDefaults.boolForKey("Authenticated") {
            alertController.addAction(userDetails)
        }
    
        switch mapView.mapType {
        case .Standard:
            alertController.addAction(mapTypeSatellite)
        case .Satellite:
            alertController.addAction(mapTypeDefault)
        default:
            break
        }
        
        alertController.addAction(cancel)
        
        presentViewController(alertController, animated: true, completion: nil)

    }

    
    //  email validation code method
    func isValidEmail(testStr:String) -> Bool {
        //let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailRegEx = "[A-Z0-9a-z._%+-]+@beamonpeople\\.se"
        if let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx) as NSPredicate? {
            return emailTest.evaluateWithObject(testStr)
        }
        return false
    }

}