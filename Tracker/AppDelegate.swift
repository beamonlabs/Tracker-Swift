//
//  AppDelegate.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-09.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import UIKit
import CoreLocation


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    
    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    var vc = ViewController()
    
    let locationManager = CLLocationManager()
    
    /*
        http://mobileoop.com/getting-location-updates-for-ios-7-and-8-when-the-app-is-killedterminatedsuspended
        Apps can expect a notification as soon as the device moves 500 meters or more from its previous notification. It should not expect notifications more frequently than once every five minutes. If the device is able to retrieve data from the network, the location manager is much more likely to deliver notifications in a timely manner.
    
        So, you could only expect the location update if the device moves over 500 meters and at most once in every 5 minutes.
    
        From my own testing (I am driving around a lot! To test the Core Locaton API), I only get the location update about every 10 minutes.
    */
    var bgLocationManager = CLLocationManager()
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // https://gooddevbaddev.wordpress.com/2013/10/22/ios-7-running-location-based-apps-in-the-background/
        // check info.plist entries - are these items needed?
        
        // http://stackoverflow.com/questions/30271271/how-to-hide-the-status-bar-programmatically-in-ios-8
        //application.statusBarHidden = true
        
        let deviceName: String! = {
            let deviceName = UIDevice.currentDevice().name
            let charSet = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzåäöüßABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖÜ1234567890- ").invertedSet
            let sanitized = deviceName.componentsSeparatedByCharactersInSet(charSet).joinWithSeparator("").stringByReplacingOccurrencesOfString(" ", withString: "-")
            
            return sanitized
        }()
        
        let settings: [String : AnyObject] = [
            "DeviceName": deviceName,
            "Authenticated": false,
            "UpdateLocation": false
        ]
        
        userDefaults.registerDefaults(settings)
        
        
        if userDefaults.boolForKey("UpdateLocation") {
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
            
            let loc = locationManager.location

            //application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil))
            //UIApplication.sharedApplication().cancelAllLocalNotifications()
            
            if  launchOptions?[UIApplicationLaunchOptionsLocationKey] != nil {
                print("[UIApplicationLaunchOptionsLocationKey] It's a location event")
                
                vc.firebase.storeLocation(loc!)
            }
        }
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        if userDefaults.boolForKey("UpdateLocation") {
            self.bgLocationManager.stopMonitoringSignificantLocationChanges()
            self.bgLocationManager.requestAlwaysAuthorization()
            self.bgLocationManager.startMonitoringSignificantLocationChanges()
        } else {
            self.bgLocationManager.stopMonitoringSignificantLocationChanges()
        }
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if userDefaults.boolForKey("UpdateLocation") {
            self.bgLocationManager.stopMonitoringSignificantLocationChanges()
            
            self.bgLocationManager = CLLocationManager()
            self.bgLocationManager.delegate = self
            self.bgLocationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            self.bgLocationManager.activityType = .OtherNavigation

            self.bgLocationManager.requestAlwaysAuthorization()
            self.bgLocationManager.startMonitoringSignificantLocationChanges()
        } else {
            self.bgLocationManager.stopMonitoringSignificantLocationChanges()
        }
    
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

