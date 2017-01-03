import CoreLocation
import Foundation
import UIKit

@UIApplicationMain
class AKAppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate
{
    // MARK: Properties
    let locationManager: CLLocationManager! = CLLocationManager()
    var masterFile: AKMasterFile = AKMasterFile()
    var window: UIWindow?
    // ### USER POSITION ### //
    var currentPosition: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var currentHeading: CLLocationDirection = CLLocationDirection(0.0)
    private var lastSavedPosition: CLLocationCoordinate2D = CLLocationCoordinate2D()
    // ### USER POSITION ### //
    private var lastSavedTime: Double = 0.0
    // The state of the App. False = Disabled because Location Service is disabled.
    var applicationActive: Bool! = true {
        didSet {
            if !applicationActive {
                NSLog("=> THE APP HAS BEEN DISABLED!")
            }
        }
    }
    
    // MARK: UIApplicationDelegate Implementation
    func applicationWillResignActive(_ application: UIApplication)
    {
        do {
            NSLog("=> SAVING *MASTER FILE* TO FILE.")
            try AKFileUtils.write(GlobalConstants.AKMasterFileName, newData: self.masterFile)
        }
        catch {
            NSLog("=> ERROR: \(error)")
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool
    {
        // Configure TabBar
        UITabBar.appearance().barTintColor = GlobalConstants.AKTabBarBg
        UITabBar.appearance().tintColor = GlobalConstants.AKTabBarTint
        UITabBarItem.appearance().setTitleTextAttributes(
            [
                NSFontAttributeName: UIFont(name: GlobalConstants.AKDefaultFont, size: 12.0) ?? UIFont.systemFont(ofSize: 12),
                NSForegroundColorAttributeName: GlobalConstants.AKDefaultFg
            ], for: UIControlState.normal
        )
        
        do {
            NSLog("=> READING *MASTER FILE* FROM FILE.")
            self.masterFile = try AKFileUtils.read(GlobalConstants.AKMasterFileName)
        }
        catch {
            NSLog("=> ERROR: \(error)")
        }
        
        // Manage Location Services
        if CLLocationManager.locationServicesEnabled() {
            // Configure Location Services
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
        else {
            NSLog("=> LOCATION NOT AVAILABLE.")
        }
        
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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let currentLocation = locations.last
        
        // Always save the current location.
        self.currentPosition = (currentLocation?.coordinate)!
        
        NSLog("=> CURRENT LAT: %f, CURRENT LON: %f", self.currentPosition.latitude, self.currentPosition.longitude)
        
        // Compute travel segment in regular intervals.
        if Int(Date().timeIntervalSince1970 - self.lastSavedTime) < GlobalConstants.AKLocationUpdateInterval {
            return
        }
        else {
            NotificationCenter.default.post(name: Notification.Name(GlobalConstants.AKLocationUpdateNotificationName), object: nil)
            
            self.lastSavedTime = Date().timeIntervalSince1970
            self.lastSavedPosition = self.currentPosition
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
    {
        if newHeading.headingAccuracy < 0 { return }
        self.currentHeading = ((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading)
        NSLog("=> CURRENT HEADING: %f", self.currentHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { NSLog("=> LOCATION SERVICES ERROR ==> \(error)") }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) { NSLog("=> LOCATION SERVICES HAS PAUSED.") }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) { NSLog("=> LOCATION SERVICES HAS RESUMED.") }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            NSLog("=> LOCATION SERVICES ==> AUTHORIZED WHEN IN USE")
            NSLog("=> READY TO START.")
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
            break
        case .restricted, .denied:
            NSLog("=> LOCATION SERVICES ==> DENIED")
            break
        default:
            break
        }
    }
}
