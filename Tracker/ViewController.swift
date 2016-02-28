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

class ViewController: UIViewController {
    
    //@IBOutlet weak var updateLocationSwitch: UISwitch!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var setTrackingModeControl: UISegmentedControl!
    @IBOutlet weak var userDetailButton: UIButton!
    
    @IBOutlet weak var locationUpdateLabel: UILabel!
    @IBOutlet weak var annotationCountLabel: UILabel!
    
    var firebase: FirebaseDB = FirebaseDB()

    var locationUpdateDistance:Double = 250
    
    var locationMeta = [String:String]()
    
    var users = [User]()

    let annotationCountLabelSuffix = " Beams"
    
    var defersLocationUpdates = false
    var defersLocationNextUpdate: NSTimeInterval = 60.0 // delay between location defers
    var defersLocationDistance: CLLocationDistance = 250 // OR/AND when moved x meter
    var desiredLocationAccuracy: Double = 31.0

    /// StyleGuide: https://github.com/raywenderlich/swift-style-guide#comments
    
    /// http://stackoverflow.com/questions/5490707/does-cllocationmanager-distancefilter-do-anything-to-conserve-power
    /// http://stackoverflow.com/questions/27281120/conserving-battery-with-ios-cllocationmanager
    /**
        One Apple sample code doc states specifically that setting a larger distanceFilter does not help in conserving power:
        ... Also, the distanceFilter does not impact the hardware's activity - i.e., there is no savings of power by setting a larger distanceFilter because the hardware continues to acquire measurements. This simply affects whether those measurements are passed on to the location manager's delegate. Power can only be saved by turning off the location manager.

        Certainly its related property distanceAccuracy has a definite impact on power management - as per the Apple docs:
            Setting the desired accuracy for location events to one kilometer gives the location manager the flexibility to turn off GPS hardware and rely solely on the WiFi or cell radios. This can lead to significant power savings.

        https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html
        The significant-change location service provides accuracy that’s good enough for most apps and represents a power-saving alternative to the standard location service. The service uses Wi-Fi to determine the user’s location and report changes in that location, allowing the system to manage power usage much more aggressively than it could otherwise.
        You can use Apple's energy diagnostics instruments to see at what desiredAccuracy level GPS chip is powered up. Our most recent investigation suggests that the GPS chip is powered when the desiredAccuracy or distanceFilter value is less than 100 meters. Energy usage values that instruments provides are very coarse for me to draw any direct co-relation between desiredAccuracy and battery usage. However, according to the popular wisdom, not turning on the GPS chip when you can is a good proxy for energy savings.
    
    */
    lazy var locationManager: CLLocationManager! = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true // this is needed for ios9 to get the location even when it's backgrounded
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters // kCLLocationAccuracyNearestTenMeters // kCLLocationAccuracyBest
        manager.distanceFilter = self.locationUpdateDistance
        manager.requestAlwaysAuthorization()
        manager.pausesLocationUpdatesAutomatically = false // not really documentated - but needed?
        
        //manager.pausesLocationUpdatesAutomatically = true
        //manager.activityType = .Fitness // .AutomotiveNavigation .Fitness

        return manager
    }()

    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    var activityIndicatorVisible = UIApplication.sharedApplication().networkActivityIndicatorVisible

    let notificationCenter = NSNotificationCenter.defaultCenter()

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // clean the labels as default
        self.locationUpdateLabel.text = ""
        self.annotationCountLabel.text = ""

        // Add observer:
        notificationCenter.addObserver(self,
            selector: Selector("applicationDidBecomeActiveNotification"),
            name: UIApplicationDidBecomeActiveNotification,
            object: nil)
        
        // Add observer:
        notificationCenter.addObserver(self,
            selector: Selector("applicationWillResignActiveNotification"),
            name: UIApplicationWillResignActiveNotification,
            object: nil)

        // FirebaseDB
        firebase.delegate = self
        
        // LocationManager
        locationManager.delegate = self
        locationManager.startUpdatingLocation() // startMonitoringSignificantLocationChanges()
        //locationManager.startMonitoringSignificantLocationChanges()
        
        // MapKit
        mapView.delegate = self
        mapView.mapType = .Standard

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        mapView.mapType = MKMapType(rawValue: 0)! // what does this do?
    }
    
    override func viewWillAppear(animated: Bool) {
        //firebase.attachEvents()
    }

    override func viewWillDisappear(animated: Bool) {
        //firebase.detachEvents()
    }


    
    /// <summary>
    ///  Helper method: what to do when tracking location enables
    /// </summary>
    func setStartUpdatingLocation() {

        self.userDefaults.setBool(true, forKey: "UpdateLocation")
        
        self.locationManager.startUpdatingLocation()

        self.mapView.userTrackingMode = .Follow // zoom to current location and follow
        
        self.firebase.attachEvents()
        
        // force store own location
        if let userLocation = self.mapView.userLocation.location {
            self.firebase.storeLocation(userLocation)
        }

    }
    
    /// <summary>
    ///  Helper method: what to do when tracking location disables
    /// </summary>
    func setStopUpdatingLocation() {

        self.userDefaults.setBool(false, forKey: "UpdateLocation")
        
        self.locationManager.stopUpdatingLocation()

        self.mapView.removeAnnotations(self.mapView.annotations)
        
        self.firebase.detachEvents()
        
        self.firebase.remove() // remove the user from firebase - security reasons
        
        self.locationMeta = [String:String]()

    }
    
    /// <summary>
    ///  Helper method: store the
    /// </summary>
    /// <param name="email">The email of the current user to store in NSUserDefaults</param>
    /// <param name="fullName">The full name of the current user to store in NSUserDefaults</param>
    func setUserDefaults(email: String, fullName: String) {
        
        // prepare Firebase user key by processing email address
        let dictKeyFromEmail : Dictionary<String, String> = [
            "@beamonpeople.se": "",
            ".": " "
        ]
        let fbUserKey = Utils.replaceByDict(email, dict: dictKeyFromEmail)
        
        self.userDefaults.setValue(fbUserKey, forKey: "FBUserKey")
        self.userDefaults.setValue(fullName, forKey: "FullName")
        self.userDefaults.setValue(email, forKey: "Email")
        
    }
    
    /// <summary>
    ///  Requests full name and email address of the current user
    /// </summary>
    func requestUserAuthentication() {

        let alert = UIAlertController(title: "Användarinformation", message: nil, preferredStyle: .Alert)
        
        let saveAction = UIAlertAction(title: "Spara",
            style: .Default) { (action: UIAlertAction!) -> Void in

            guard let fullName = ((alert.textFields?.first)! as UITextField).text else {
                NSLog("Corrupt Data: %@", "fullName")
                return
            }
            
            guard let email = ((alert.textFields?.last)! as UITextField).text else {
                NSLog("Corrupt Data: %@", "email")
                return
            }

            // store data in NSUserDefaults
            self.setUserDefaults(email, fullName: fullName)
            
            // if not already authenticated (first time register)
            if !self.userDefaults.boolForKey("Authenticated") {
                
                self.userDefaults.setBool(true, forKey: "Authenticated")
                
                self.setStartUpdatingLocation()
                
            }
                
        }
        saveAction.enabled = false
        
        let cancelAction = UIAlertAction(title: "Avbryt",
            style: .Default) { (action: UIAlertAction!) -> Void in
                /*
                // if already authenticated, don't reset switch state
                if !self.userDefaults.boolForKey("Authenticated") {
                    // reset switch to "off"
                    self.updateLocationSwitch.on = false
                }
                */
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
    

    
    
    /// <summary>
    ///  Set the map tracking mode related to the choosen button
    /// </summary>
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
    
    /// <summary>
    ///  [DEPRECATED] What to do when switch for en/disable track location changed state
    /// </summary>
    /// http://www.ioscreator.com/tutorials/uiswitch-tutorial-in-ios8-with-swift
    /*
    @IBAction func onUpdateLocationSwitchChange(sender: UISwitch) {
        if(updateLocationSwitch.on) {
            
            if userDefaults.boolForKey("Authenticated") { //NSLog("%@", "Access granted.")
                self.userDefaults.setBool(true, forKey: "UpdateLocation")
                
                self.locationManager.startUpdatingLocation()
                //self.locationManager.startMonitoringSignificantLocationChanges()
                self.mapView.userTrackingMode = .Follow // zoom to current location and follow
                
                firebase.attachEvents()

                // force setting
                let userLocation = self.mapView.userLocation.location
                firebase.storeLocation(userLocation!)
                
            } else {
                self.requestUserAuthentication()
            }

        } else {

            self.userDefaults.setBool(false, forKey: "UpdateLocation")
            
            self.locationManager.stopUpdatingLocation()
            //self.locationManager.stopMonitoringSignificantLocationChanges()
            self.mapView.removeAnnotations(self.mapView.annotations)

            firebase.detachEvents()
            
            firebase.remove() // remove the user from firebase - security reasons
            
            self.locationMeta = [String:String]()
        
        }
    }
    */
    
    /// <summary>
    ///  Open "settings" when clicked on info button
    /// </summary>
    @IBAction func onInfoButton(sender: UIButton) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let meta = self.locationMeta
        if !meta.isEmpty {
            alertController.title = meta["title"]
            alertController.message = meta["location"]
        }
        
        let userDetails = UIAlertAction(title: "Användarinformation", style: .Default, handler: { (action) -> Void in
            self.requestUserAuthentication()
        })
        
        let mapTypeDefault = UIAlertAction(title: "Karta", style: .Default, handler: { (action) -> Void in
            self.mapView.mapType = .Standard
        })
        
        let mapTypeSatellite = UIAlertAction(title: "Satellit", style: .Default, handler: { (action) -> Void in
            self.mapView.mapType = .Satellite
        })

        let enableLocationUpdate = UIAlertAction(title: "Spåra min position", style: .Default, handler: { (action) -> Void in
            if self.userDefaults.boolForKey("Authenticated") { //NSLog("%@", "Access granted.")
                self.setStartUpdatingLocation()
            } else {
                self.requestUserAuthentication()
            }
        })
        let disableLocationUpdate = UIAlertAction(title: "Sluta spåra min position", style: .Destructive, handler: { (action) -> Void in
            self.setStopUpdatingLocation()
        })

        let cancel = UIAlertAction(title: "Avbryt", style: .Cancel, handler: { (action) -> Void in
            // TODO
        })
        

        if self.userDefaults.boolForKey("UpdateLocation") {
            alertController.addAction(disableLocationUpdate)
        } else {
            alertController.addAction(enableLocationUpdate)
        }

        if self.userDefaults.boolForKey("Authenticated") {
            alertController.addAction(userDetails)
        }

        switch self.mapView.mapType {
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
    
    /// <summary>
    ///  Helper method to check for valid email
    /// </summary>
    func isValidEmail(testStr:String) -> Bool {
        //let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailRegEx = "[A-Z0-9a-z._%+-]+@beamonpeople\\.se"
        if let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx) as NSPredicate? {
            return emailTest.evaluateWithObject(testStr)
        }
        return false
    }

}