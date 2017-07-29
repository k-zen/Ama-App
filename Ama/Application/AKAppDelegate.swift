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
    private var lastSavedPosition: GeoCoordinate?
    // ### USER POSITION ### //
    private var lastSavedTime = 0.0
    
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
        let token = deviceToken.reduce("", { $0 + String(format: "%02X", $1) })
        
        if !Func.AKGetUser().isRegistered {
            Func.AKGetUser().username = token
            Func.AKGetUser().password = String(format: "%i", arc4random_uniform(1000000) + (1000000 * (arc4random_uniform(9) + 1)))
            
            Func.AKExecute(mode: .asyncBackground, timeDelay: 0.0) {
                AKWSUtils.makeRESTRequest(
                    controller: nil,
                    endpoint: String(format: "%@/ama/user/existe", GlobalConstants.AKAmaServerAddress),
                    httpMethod: "POST",
                    headerValues: [
                        "Content-Type"  : "application/json",
                        "Authorization" : "Ama@admin:amaPass2017".toBase64()
                    ],
                    bodyValue: Func.AKGetUser().username,
                    showDebugInfo: false,
                    isJSONResponse: false,
                    completionTask: { (json) -> Void in
                        // Process the results.
                        if let str = json as? String {
                            if str.caseInsensitiveCompare("false") == ComparisonResult.orderedSame {
                                AKWSUtils.makeRESTRequest(
                                    controller: nil,
                                    endpoint: String(format: "%@/ama/user/insertar", GlobalConstants.AKAmaServerAddress),
                                    httpMethod: "POST",
                                    headerValues: [
                                        "Content-Type"  : "application/json",
                                        "Authorization" : "Ama@admin:amaPass2017".toBase64()
                                    ],
                                    bodyValue: String(
                                        format: "{\"username\":\"%@\",\"password\":\"%@\"}",
                                        Func.AKGetUser().username,
                                        Func.AKGetUser().password
                                    ),
                                    showDebugInfo: false,
                                    isJSONResponse: false,
                                    completionTask: { (json) -> Void in Func.AKGetUser().registerUser() },
                                    failureTask: { (code, message) -> Void in NSLog("=> ERROR: CODE=%i, MESSAGE=%@", code, message ?? "") }
                                )
                            }
                            else {
                                // The user already exists, which means the token has been registered,
                                // let it pass.
                                Func.AKGetUser().registerUser()
                            }
                        } },
                    failureTask: { (code, message) -> Void in NSLog("=> ERROR: CODE=%i, MESSAGE=%@", code, message ?? "") }
                )
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("=> ERROR: \(error)")
    }
}
