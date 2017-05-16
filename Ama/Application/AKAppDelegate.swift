import CoreLocation
import Foundation
import UIKit
import UserNotifications

@UIApplicationMain
class AKAppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    // MARK: Properties
    let notificationCenter = UNUserNotificationCenter.current()
    let locationManager = CLLocationManager()
    var masterFile = AKMasterFile()
    var window: UIWindow?
    // ### USER POSITION ### //
    var currentPosition: GeoCoordinate?
    var currentHeading = CLLocationDirection(0.0)
    private var lastSavedPosition: GeoCoordinate?
    // ### USER POSITION ### //
    private var lastSavedTime = 0.0
    var applicationActive: Bool = true {
        didSet {
            if !applicationActive {
                if GlobalConstants.AKDebug {
                    NSLog("=> THE APP HAS BEEN DISABLED!")
                }
            }
        }
    }
    
    // MARK: UIApplicationDelegate Implementation
    func applicationWillResignActive(_ application: UIApplication) {
        // Persist data.
        do {
            NSLog("=> SAVING *MASTER FILE* TO FILE.")
            NSLog("%@", self.masterFile.printObject())
            try AKFileUtils.write(GlobalConstants.AKMasterFileName, newData: self.masterFile)
        }
        catch {
            NSLog("=> ERROR: \(error)")
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // ### Customize the App.
        UITabBarItem.appearance().setTitleTextAttributes([
            NSFontAttributeName: UIFont(
                name: GlobalConstants.AKSecondaryFont,
                size: GlobalConstants.AKTabBarFontSize) ?? UIFont.systemFont(ofSize: GlobalConstants.AKTabBarFontSize),
            NSForegroundColorAttributeName: GlobalConstants.AKTabBarTintNormal
            ], for: .normal
        )
        UITabBarItem.appearance().setTitleTextAttributes([
            NSFontAttributeName: UIFont(
                name: GlobalConstants.AKSecondaryFont,
                size: GlobalConstants.AKTabBarFontSize) ?? UIFont.systemFont(ofSize: GlobalConstants.AKTabBarFontSize),
            NSForegroundColorAttributeName: GlobalConstants.AKTabBarTintSelected
            ], for: .selected
        )
        UITabBar.appearance().barTintColor = GlobalConstants.AKTabBarBg
        UINavigationBar.appearance().titleTextAttributes = [
            NSFontAttributeName: UIFont(
                name: GlobalConstants.AKSecondaryFont,
                size: GlobalConstants.AKNavBarFontSize) ?? UIFont.systemFont(ofSize: GlobalConstants.AKNavBarFontSize),
            NSForegroundColorAttributeName: GlobalConstants.AKDefaultFg
        ]
        UINavigationBar.appearance().tintColor = GlobalConstants.AKTabBarTintSelected
        
        // Read persisted data.
        do {
            NSLog("=> READING *MASTER FILE* FROM FILE.")
            self.masterFile = try AKFileUtils.read(GlobalConstants.AKMasterFileName)
        }
        catch {
            NSLog("=> ERROR: \(error)")
        }
        
        // Manage Location Services
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
        else {
            NSLog("=> LOCATION NOT AVAILABLE.")
        }
        
        // Manage Notifications.
        self.notificationCenter.delegate = self
        application.registerForRemoteNotifications()
        
        // Start heading updates.
        if CLLocationManager.headingAvailable() {
            self.locationManager.headingFilter = 5
        }
        else {
            NSLog("=> HEADING NOT AVAILABLE.")
        }
        
        return true
    }
    
    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations.last
        self.currentPosition = (currentLocation?.coordinate)!
        
        if GlobalConstants.AKDebug {
            NSLog("=> CURRENT LAT: %f, CURRENT LON: %f", self.currentPosition?.latitude ?? kCLLocationCoordinate2DInvalid.latitude, self.currentPosition?.longitude ?? kCLLocationCoordinate2DInvalid.longitude)
        }
        
        if Int(Date().timeIntervalSince1970 - self.lastSavedTime) < GlobalConstants.AKLocationUpdateInterval {
            return
        }
        else {
            NotificationCenter.default.post(name: Notification.Name(GlobalConstants.AKLocationUpdateNotificationName), object: nil)
            self.lastSavedTime = Date().timeIntervalSince1970
            self.lastSavedPosition = self.currentPosition
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 {
            return
        }
        self.currentHeading = ((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading)
        NSLog("=> CURRENT HEADING: %f", self.currentHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("=> LOCATION SERVICES ERROR ==> \(error)")
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        NSLog("=> LOCATION SERVICES HAS PAUSED.")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        NSLog("=> LOCATION SERVICES HAS RESUMED.")
    }
    
    // MARK: UNUserNotificationCenterDelegate Implementation
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Func.AKGetUser().apnsToken = deviceToken.reduce("", { $0 + String(format: "%02X", $1) })
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("=> ERROR: \(error)")
    }
}
