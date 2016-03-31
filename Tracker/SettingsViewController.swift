//
//  SettingsViewController.swift
//  Tracker
//
//  Created by Stefan Dressler on 2016-02-29.
//  Copyright © 2016 Beamon People AB. All rights reserved.
//

import UIKit


class SettingsViewController: UITableViewController, GIDSignInUIDelegate {

    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!

    @IBOutlet weak var storeLocationUpdatesSwitch: UISwitch!
    
    @IBOutlet weak var fullNameDetail: UILabel!
    @IBOutlet weak var emailDetail: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var fullName:String = "Förnamn Efternamn"
        var email:String = "fornamn.efternamn@beamonpeople.se"
        
        if let userDefaultsFullName = userDefaults.stringForKey("FullName") {
            if userDefaultsFullName != "" {
                fullName = userDefaultsFullName
            }
        }
        if let userDefaultsEmail = userDefaults.stringForKey("Email") {
            if userDefaultsEmail != "" {
                email = userDefaultsEmail
            }
        }

        self.fullNameDetail.text = fullName
        self.emailDetail.text = email
        

        /// https://developers.google.com/ios/guides/releases#december_2015
        /// -> App measurement en/disable

        GIDSignIn.sharedInstance().uiDelegate = self

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(SettingsViewController.receiveToggleAuthUINotification(_:)),
            name: "ToggleAuthUINotification",
            object: nil)
        
        toggleAuthUI()

        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imageForImageURLString(imageURLString: String, completion: (image: UIImage?, success: Bool) -> Void) {
        guard let url = NSURL(string: imageURLString),
            let data = NSData(contentsOfURL: url),
            let image = UIImage(data: data)
            else {
                completion(image: nil, success: false);
                return
        }
        
        completion(image: image, success: true)
    }
    
    /// http://stackoverflow.com/questions/24231680/loading-image-from-url
    func imageFromUrl(urlString: String) {
        self.imageForImageURLString(urlString) { (image, success) -> Void in
            if success {
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    guard let image = image
                        else { return } // Error handling here
                    
                    // You now have the image. Use the image to update the view or anything UI related here
                    // Reload the view, so the image appears
                    self.avatar.image = image
                }
            } else {
                // Error handling here.
            }
        }
    }
    
    
    // [START toggle_auth]
    func toggleAuthUI() {
        if let imageUrl = self.userDefaults.stringForKey("Avatar") {
            self.imageFromUrl(imageUrl)
        }

        if (GIDSignIn.sharedInstance().hasAuthInKeychain()) {
            // Signed in
            self.userDefaults.setBool(true, forKey: "Authenticated")
            
            self.storeLocationUpdatesSwitch.enabled = true
            if userDefaults.boolForKey("UpdateLocation") {
                self.storeLocationUpdatesSwitch.on = true
            } else {
                self.storeLocationUpdatesSwitch.on = false
            }
            
            signInButton.hidden = true
            signOutButton.hidden = false
            disconnectButton.hidden = false
        } else {
            self.userDefaults.setBool(false, forKey: "Authenticated")
            
            self.userDefaults.setBool(false, forKey: "UpdateLocation")
            self.storeLocationUpdatesSwitch.on = false
            self.storeLocationUpdatesSwitch.enabled = false

            signInButton.hidden = false
            signOutButton.hidden = true
            disconnectButton.hidden = true
        }

        //print("[GOOGLE] ToggleAuthUI \(userDefaults.boolForKey("Authenticated")) \(userDefaults.boolForKey("UpdateLocation"))")
    }
    // [END toggle_auth]
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: "ToggleAuthUINotification",
            object: nil)
    }
    
    
    /// needed when login and toogleAuth wanted after it to update UI
    @objc func receiveToggleAuthUINotification(notification: NSNotification) {
        if (notification.name == "ToggleAuthUINotification") {
            print("receiveToggleAuthUINotification")
            self.toggleAuthUI()

            /*
            if notification.userInfo != nil {
                let userInfo:Dictionary<String,String!> =
                notification.userInfo as! Dictionary<String,String!>
                //self.statusText.text = userInfo["statusText"]
            }
            */
        }
    }
    
    
    
    @IBAction func toggleStoreLocationUpdatesSwitch(sender: UISwitch) {
        if (sender.on) {
            self.userDefaults.setBool(true, forKey: "UpdateLocation")
        } else {
            self.userDefaults.setBool(false, forKey: "UpdateLocation")
        }
    }
    
    @IBAction func didTapSignIn(sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
        //toggleAuthUI()
    }
    
    @IBAction func didTapSignOut(sender: AnyObject) {
        GIDSignIn.sharedInstance().signOut()
        toggleAuthUI()
    }
    
    @IBAction func didTapDisconnect(sender: AnyObject) {
        GIDSignIn.sharedInstance().disconnect()
    }
    
    
    
    
    // MARK: - Table view data source

    /*
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    */

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
