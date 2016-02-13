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
    @IBOutlet weak var authenticateButton: UIButton!
    
    
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

    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    //let deviceName = UIDevice.currentDevice().name // users device name - instead of GoogleAccountAuth
    
    var activityIndicatorVisible = UIApplication.sharedApplication().networkActivityIndicatorVisible


    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        firebase = Firebase(url: "https://crackling-torch-7934.firebaseio.com/beamontracker/users")

        locationManager.startUpdatingLocation() // startMonitoringSignificantLocationChanges()
        
        mapView.delegate = self
        mapView.mapType = .Standard

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
        
        if userDefaults.boolForKey("Authenticated") {
            NSLog("%@", "Access granted.")
            self.authenticateButton.hidden = true
            self.attachFirebaseEvents()
        } else {
            self.authenticateButton.hidden = false
            NSLog("%@", "Access denied.")
        }

    }

    override func viewWillDisappear(animated: Bool) {
        
        self.detachFirebaseEvents()
        
        //locationManager.stopUpdatingHeading()
        
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
    
    
    
    

    //  email validation code method
    func isValidEmail(testStr:String) -> Bool {
        //let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailRegEx = "[A-Z0-9a-z._%+-]+@beamonpeople\\.se"
        if let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx) as NSPredicate? {
            return emailTest.evaluateWithObject(testStr)
        }
        return false
    }
    
    @IBAction func authenticate(sender: UIButton) {
        // https://github.com/mattneub/Programming-iOS-Book-Examples/blob/master/bk2ch13p620dialogsOniPhone/ch26p888dialogsOniPhone/ViewController.swift
        // http://stackoverflow.com/questions/30596851/how-do-i-validate-textfields-in-an-uialertcontroller

        
        let alert = UIAlertController(title: "Fyll i dina uppgifter:", message: nil, preferredStyle: .Alert)
        
        let saveAction = UIAlertAction(title: "Save", 
            style: .Default) { (action: UIAlertAction!) -> Void in

                // prepare Firebase user key by processing email address
                let dictKeyFromEmail : Dictionary<String, String> = [
                    "@beamonpeople.se": "",
                    ".": " "
                ]

                if let fullName = ((alert.textFields?.first)! as UITextField).text {
                    self.userDefaults.setValue(fullName, forKey: "FullName")
                }
                
                if let email = ((alert.textFields?.last)! as UITextField).text {
                    self.userDefaults.setValue(email, forKey: "Email")

                    let fbUserKey = Utils.replaceByDict(email, dict: dictKeyFromEmail)
                    self.userDefaults.setValue(fbUserKey, forKey: "FBUserKey")
                }
                

                // TODO: check if all values are set correct
                
                
                self.userDefaults.setBool(true, forKey: "Authenticated")
                
                self.attachFirebaseEvents()
                
                // hide button
                sender.hidden = true
        }
        saveAction.enabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel",
            style: .Default) { (action: UIAlertAction!) -> Void in
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

}