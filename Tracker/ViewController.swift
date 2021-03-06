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

class ViewController: UIViewController, GIDSignInUIDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var setTrackingModeControl: UISegmentedControl!
    @IBOutlet weak var userDetailButton: UIButton!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var locationUpdateLabel: UILabel!
    @IBOutlet weak var annotationCountLabel: UILabel!
    
    //var firebase: FirebaseDB = FirebaseDB()
    var firebase = FirebaseDB.sharedInstance

    var locationUpdateDistance:Double = 250
    
    var locationMeta = [String:String]()
    
    var users = [User]()
    
    var data = [User]()
    var filtered:[User] = []

    
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
        //manager.activityType = .Fitness // .AutomotiveNavigation .Fitness
        return manager
    }()

    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    var activityIndicatorVisible = UIApplication.sharedApplication().networkActivityIndicatorVisible

    let notificationCenter = NSNotificationCenter.defaultCenter()

    var searchActive : Bool = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround() // when tapped on sth - end editing, e.g. search
        
        GIDSignIn.sharedInstance().uiDelegate = self

        if (GIDSignIn.sharedInstance().hasAuthInKeychain()) {
            print("[GOOGLE] Has Auth In Keychain")
            // Uncomment to automatically sign in the user.
            GIDSignIn.sharedInstance().signInSilently()
        } else {
            print("[GOOGLE] No Auth In Keychain -> Request SignIn")
            GIDSignIn.sharedInstance().signIn()
        }

        // FirebaseDB
        firebase.delegate = self
        
        // LocationManager
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        
        // MapKit
        mapView.delegate = self
        mapView.mapType = .Standard
        
        // table view and search bar
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        // clean the labels as default
        self.locationUpdateLabel.text = ""
        self.annotationCountLabel.text = ""
        
        notificationCenter.addObserver(
            self,
            selector: #selector(ViewController.applicationDidBecomeActiveNotification),
            name: UIApplicationDidBecomeActiveNotification,
            object: nil)

        notificationCenter.addObserver(
            self,
            selector: #selector(ViewController.applicationWillResignActiveNotification),
            name: UIApplicationWillResignActiveNotification,
            object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //mapView.mapType = MKMapType(rawValue: 0)! // what does this do?
    }
    
    override func viewWillAppear(animated: Bool) {
        if userDefaults.boolForKey("UpdateLocation") {
            self.setStartUpdatingLocation()
        } else {
            self.setStopUpdatingLocation()
        }
        
        print("appear \(userDefaults.objectForKey("track_location"))")
        
        //self.firebase.attachEvents()
    }

    override func viewWillDisappear(animated: Bool) {
        self.firebase.detachEvents()
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
    ///  Open "settings" when clicked on info button
    /// </summary>
    @IBAction func onInfoButton(sender: UIButton) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let meta = self.locationMeta
        if !meta.isEmpty {
            alertController.title = meta["title"]
            alertController.message = meta["location"]
        }
        
        let mapTypeDefault = UIAlertAction(title: "Karta", style: .Default, handler: { (action) -> Void in
            self.mapView.mapType = .Standard
        })
        
        let mapTypeSatellite = UIAlertAction(title: "Satellit", style: .Default, handler: { (action) -> Void in
            self.mapView.mapType = .Satellite
        })

        let cancel = UIAlertAction(title: "Avbryt", style: .Cancel, handler: { (action) -> Void in
            // TODO
        })

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
    
    @IBAction func onSearchButton(sender: UIBarButtonItem) {
        searchBar.hidden = !searchBar.hidden
        
        if(searchBar.hidden == true) {
            searchBar.endEditing(true)
            tableView.hidden = true
        } else {
            searchBar.becomeFirstResponder()
            tableView.hidden = false
        }
    }

}




// Put this piece of code anywhere you like --- hideKeyboardWhenTapped
/*
extension UIViewController {
}
*/
extension ViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        mapView.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
        searchActive = false
        
        searchBar.hidden = true
        tableView.hidden = true
    }
}



// special for TableView and Search
/// http://stackoverflow.com/questions/11284321/what-is-the-height-of-iphones-onscreen-keyboard
/// http://stackoverflow.com/questions/25874975/cant-get-correct-value-of-keyboard-height-in-ios8
/// http://stackoverflow.com/questions/25851626/programatically-get-keyboard-frame-in-swift
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(searchActive) {
            return filtered.count
        }
        return data.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")! as UITableViewCell;
        
        let currentItem = (searchActive) ? filtered[indexPath.row] : data[indexPath.row]
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let d = dateFormatter.dateFromString(currentItem.timestamp)
        let ds = d!.timeAgo
        
        cell.textLabel?.text = currentItem.fullName
        cell.detailTextLabel?.text = ds + " " + currentItem.locationName
        
        return cell;
    }

    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCellUsername = tableView.cellForRowAtIndexPath(indexPath)?.textLabel!.text
        
        for annotation in self.mapView.annotations {
            if annotation is CustomAnnotation {
                let ann = annotation as! CustomAnnotation
                var fullName = ""
                
                if let _fullName = ann.user?.fullName {
                    fullName = _fullName
                }
                
                if fullName.containsString(selectedCellUsername!) {
                    //print("selected \(fullName) \(ann.user?.location)")
                    
                    // will hide search as well
                    self.dismissKeyboard()
                    
                    let location = ann.user?.location
                    
                    let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
                    let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                    
                    self.mapView.setRegion(region, animated: true)
                    // select the annotation/show title
                    self.mapView.selectAnnotation(ann, animated: true)
                    
                }
                
            }
        }
    }
    

}


// special for TableView and Search
extension ViewController: UISearchBarDelegate {

    /// http://shrikar.com/swift-ios-tutorial-uisearchbar-and-uisearchbardelegate/
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        if (searchBar.text?.characters.count > 0) {
            searchActive = true
        } else {
            searchActive = false
        }
    }
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filtered = data.filter() { $0.fullName.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil }
        
        searchActive = !(filtered.count == 0)

        self.tableView.hidden = (filtered.count == 0)
        
        self.tableView.reloadData()
    }

}

