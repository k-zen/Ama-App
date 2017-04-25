import Foundation
import MapKit

/// Wrapper class to describe a user and it's properties.
///
/// - Author: Andreas P. Koenzen <akc@apkc.net>
/// - Copyright: 2017 APKC.net
/// - Date: Jan 24, 2017
class AKUser: NSObject, NSCoding
{
    // MARK: Constants
    struct Keys {
        static let username = "AK.user.username"
        static let password = "AK.user.password"
        static let apnsToken = "AK.user.apns.token"
        static let isRegistered = "AK.user.is.registered"
        static let userDefinedAlerts = "AK.user.defined.alerts"
    }
    
    // MARK: Properties
    var username: String
    var password: String
    var apnsToken: String
    var isRegistered: Bool
    var userDefinedAlerts: [Alert]
    
    // MARK: Initializers
    override init()
    {
        self.username = GlobalConstants.AKEmptyPhoneNumber
        self.password = ""
        self.apnsToken = ""
        self.isRegistered = false
        self.userDefinedAlerts = []
    }
    
    init(username: String, password: String, apnsToken: String, isRegistered: Bool, userDefinedAlerts: [Alert])
    {
        self.username = username
        self.password = password
        self.apnsToken = apnsToken
        self.isRegistered = isRegistered
        self.userDefinedAlerts = userDefinedAlerts
        
        super.init()
    }
    
    // MARK: Alert Management
    func addAlert(alert: Alert)
    {
        for a in self.userDefinedAlerts {
            if a.alertID.caseInsensitiveCompare(alert.alertID) == ComparisonResult.orderedSame {
                return
            }
        }
        
        self.userDefinedAlerts.append(alert)
    }
    
    func removeAlert(mapView: MKMapView, id: String, shouldRemoveAll: Bool = false, shouldRemoveLast: Bool = false) -> Bool
    {
        if shouldRemoveAll {
            mapView.removeAnnotations(mapView.annotations.filter({ (annotation) -> Bool in
                if annotation.isKind(of: AKAlertAnnotation.self) {
                    return true
                }
                else {
                    return false
                }
            }))
            self.userDefinedAlerts.removeAll()
            NSLog("=> INFO: ALL ALERTS DISCARTED!")
            
            return true
        }
        else {
            if shouldRemoveLast {
                if let last = self.userDefinedAlerts.last { // Correct bug: A ghost view appear behind annotation views because the view could not be deselected before removing.
                    mapView.deselectAnnotation(last.alertAnnotation, animated: true)
                    if let alert = self.removeLastAlert() {
                        mapView.removeAnnotation(alert.alertAnnotation)
                        NSLog("=> INFO: LAST ALERT DISCARTED!")
                        
                        return true
                    }
                }
            }
            else {
                for (i, a) in self.userDefinedAlerts.enumerated() {
                    if a.alertID.caseInsensitiveCompare(id) == ComparisonResult.orderedSame {
                        mapView.removeAnnotation(a.alertAnnotation)
                        self.userDefinedAlerts.remove(at: i)
                        NSLog("=> INFO: PIN %@ DISCARTED!", id)
                        
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    func removeLastAlert() -> Alert?
    {
        return self.userDefinedAlerts.popLast()
    }
    
    func countAlerts() -> Int
    {
        return self.userDefinedAlerts.count
    }
    
    func findAlert(id: String) -> Alert?
    {
        for a in self.userDefinedAlerts {
            if a.alertID.caseInsensitiveCompare(id) == ComparisonResult.orderedSame {
                return a
            }
        }
        
        return nil
    }
    
    // MARK: Manage registration.
    func registerUser()
    {
        if !self.isRegistered {
            self.isRegistered = true
        }
    }
    
    // MARK: Utilities
    func printObject(_ padding: String = "") -> String
    {
        let string: NSMutableString = NSMutableString()
        
        string.appendFormat("%@****** USER ******\n", padding)
        string.appendFormat("%@>>> Username = %@\n", padding, self.username)
        string.appendFormat("%@>>> Password = %@\n", padding, self.password)
        string.appendFormat("%@>>> APNS Token = %@\n", padding, self.apnsToken)
        string.appendFormat("%@>>> Is Registered = %@\n", padding, self.isRegistered ? "YES" : "NO")
        string.appendFormat("%@>>> User Defined Alerts (%i) = %@\n", padding, self.userDefinedAlerts.count, self.userDefinedAlerts)
        for alert in self.userDefinedAlerts {
            string.appendFormat("%@", alert.printObject("\t"))
        }
        string.appendFormat("%@****** USER ******\n", padding)
        
        return string as String
    }
    
    // MARK: NSCoding Implementation
    required convenience init(coder aDecoder: NSCoder)
    {
        let username = aDecoder.decodeObject(forKey: Keys.username) as! String
        let password = aDecoder.decodeObject(forKey: Keys.password) as! String
        let apnsToken = aDecoder.decodeObject(forKey: Keys.apnsToken) as! String
        let isRegistered = aDecoder.decodeBool(forKey: Keys.isRegistered)
        let userDefinedAlerts = aDecoder.decodeObject(forKey: Keys.userDefinedAlerts) as! [Alert]
        
        self.init(username: username, password: password, apnsToken: apnsToken, isRegistered: isRegistered, userDefinedAlerts: userDefinedAlerts)
    }
    
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self.username, forKey: Keys.username)
        aCoder.encode(self.password, forKey: Keys.password)
        aCoder.encode(self.apnsToken, forKey: Keys.apnsToken)
        aCoder.encode(self.isRegistered, forKey: Keys.isRegistered)
        aCoder.encode(self.userDefinedAlerts, forKey: Keys.userDefinedAlerts)
    }
}
