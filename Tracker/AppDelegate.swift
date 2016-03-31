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
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate, CLLocationManagerDelegate {

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
        
        let appInfo = NSBundle.mainBundle().infoDictionary! as Dictionary<String,AnyObject>
        let shortVersionString = appInfo["CFBundleShortVersionString"] as! String
        let bundleVersion = appInfo["CFBundleVersion"] as! String
        let applicationVersion = shortVersionString + "." + bundleVersion
        
        
        /// Google SignIn needs ENABLE_BITCODE = NO to run on iPhone
        /// http://stackoverflow.com/questions/31205133/how-to-enable-bitcode-in-xcode-7

        // Initialize Google sign-in
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        GIDSignIn.sharedInstance().delegate = self
        
        
        
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

        userDefaults.setObject(applicationVersion, forKey: "application_version")
        //userDefaults.synchronize()
        
        
        if userDefaults.boolForKey("UpdateLocation") {
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
            
            let loc = locationManager.location

            if launchOptions?[UIApplicationLaunchOptionsLocationKey] != nil {
                vc.firebase.storeLocation(loc!)
            }
        }
        
        return true
    }
    
    
    
    
    
    /// <summary>
    ///  GIDSignIn Helper method to open URL for auth redirect
    /// </summary>
    /// <param name="application"></param>
    /// <param name="openURL"></param>
    /// <param name="sourceApplication"></param>
    /// <param name="annotation"></param>
    func application(application: UIApplication,
        openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
            return GIDSignIn.sharedInstance().handleURL(url,
                sourceApplication: sourceApplication,
                annotation: annotation)
    }
    
    /// <summary>
    ///  GIDSignIn Helper method to open URL for auth redirect
    /// </summary>
    /// <param name="application"></param>
    /// <param name="openURL"></param>
    /// <param name="options"></param>
    func application(app: UIApplication,
        openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return GIDSignIn.sharedInstance().handleURL(url,
            sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey] as! String?,
            annotation: options[UIApplicationOpenURLOptionsAnnotationKey])
    }
    
    /// <summary>
    ///  GIDSignIn Signin handler
    ///  Perform any operations on signed in user here.
    /// </summary>
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!,
        withError error: NSError!) {
            if (error == nil) {
                //let userId = user.userID                  // For client-side use only!
                //let idToken = user.authentication.idToken // Safe to send to the server
                let fullName = user.profile.name
                let email = user.profile.email
                
                var avatar:String = ""
                
                if user.profile.hasImage {
                    let imageUrl = signIn.currentUser.profile.imageURLWithDimension(128)
                    avatar = imageUrl.absoluteString
                }
                
                // store data in NSUserDefaults
                self.setUserDefaults(email, fullName: fullName, avatar: avatar)
                
                //print("[GOOGLE] \(email) \(fullName)")

                NSNotificationCenter.defaultCenter().postNotificationName(
                    "ToggleAuthUINotification",
                    object: nil,
                    userInfo: ["statusText": "Signed in user:\n\(fullName)"])
            } else {
                //print("[GOOGLE] Not authenticated.")

                print("\(error.localizedDescription)")

                NSNotificationCenter.defaultCenter().postNotificationName(
                    "ToggleAuthUINotification",
                    object: nil,
                    userInfo: nil)
            }
    }

    /// <summary>
    ///  GIDSignIn Disconnect handler
    ///  Perform any operations when the user disconnects from app here.
    /// </summary>
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!,
        withError error: NSError!) {
            // remove from Firebase - needs to be BEFORE unset defaults
            FirebaseDB.sharedInstance.remove()

            self.unsetUserDefaults()
            
            NSNotificationCenter.defaultCenter().postNotificationName(
                "ToggleAuthUINotification",
                object: nil,
                userInfo: ["statusText": "User has disconnected."])
    }

    
    /// <summary>
    ///  Helper method: store the user settings
    /// </summary>
    /// <param name="email">The email of the current user to store in NSUserDefaults</param>
    /// <param name="fullName">The full name of the current user to store in NSUserDefaults</param>
    /// <param name="avatar">The URL to the avatar image</param>
    func setUserDefaults(email: String, fullName: String, avatar: String) {
        
        // prepare Firebase user key by processing email address
        let dictKeyFromEmail : Dictionary<String, String> = [
            "@beamonpeople.se": "",
            ".": " "
        ]
        let fbUserKey = Utils.replaceByDict(email, dict: dictKeyFromEmail)
        
        self.userDefaults.setValue(fbUserKey, forKey: "FBUserKey")
        self.userDefaults.setValue(fullName, forKey: "FullName")
        self.userDefaults.setValue(email, forKey: "Email")
        self.userDefaults.setValue(avatar, forKey: "Avatar")
        
    }

    /// <summary>
    ///  Helper method: remove the user settings
    /// </summary>
    func unsetUserDefaults() {
        
        self.userDefaults.setValue("", forKey: "FullName")
        self.userDefaults.setValue("", forKey: "Email")
        self.userDefaults.setValue("", forKey: "Avatar")
        
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

