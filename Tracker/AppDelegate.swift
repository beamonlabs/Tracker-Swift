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
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // http://stackoverflow.com/questions/30271271/how-to-hide-the-status-bar-programmatically-in-ios-8
        application.statusBarHidden = true
        
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
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        application.beginBackgroundTaskWithExpirationHandler {}
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        application.beginBackgroundTaskWithExpirationHandler {}
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        application.beginBackgroundTaskWithExpirationHandler {}
    }

}

