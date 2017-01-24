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
        static let phoneNumber = "AK.phone.number"
        static let userDefinedAlerts = "AK.user.defined.alerts"
    }
    
    // MARK: Properties
    static let AKEmptyPhoneNumber = "000000"
    var phoneNumber: String
    var userDefinedAlerts: [AKAlert]
    
    // MARK: Initializers
    override init()
    {
        self.phoneNumber = AKUser.AKEmptyPhoneNumber
        self.userDefinedAlerts = []
    }
    
    init(phoneNumber: String, userDefinedAlerts: [AKAlert])
    {
        self.phoneNumber = phoneNumber
        self.userDefinedAlerts = userDefinedAlerts
        super.init()
    }
    
    // MARK: Alert Management
    func addAlert(alert: AKAlert)
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
    
    func removeLastAlert() -> AKAlert?
    {
        return self.userDefinedAlerts.popLast()
    }
    
    func countAlerts() -> Int
    {
        return self.userDefinedAlerts.count
    }
    
    func findAlert(id: String) -> AKAlert?
    {
        for a in self.userDefinedAlerts {
            if a.alertID.caseInsensitiveCompare(id) == ComparisonResult.orderedSame {
                return a
            }
        }
        
        return nil
    }
    
    // MARK: Utilities
    func printObject(_ padding: String = "") -> String
    {
        let string: NSMutableString = NSMutableString()
        
        string.appendFormat("%@****** USER ******\n", padding)
        string.appendFormat("%@\t>>> Phone Number = %@\n", padding, self.phoneNumber)
        string.appendFormat("%@\t>>> User Defined Alerts (%i) = %@\n", padding, self.userDefinedAlerts.count, self.userDefinedAlerts)
        string.appendFormat("%@****** USER ******\n", padding)
        
        return string as String
    }
    
    // MARK: NSCoding Implementation
    required convenience init(coder aDecoder: NSCoder)
    {
        let phoneNumber = aDecoder.decodeObject(forKey: Keys.phoneNumber) as! String
        let userDefinedAlerts = aDecoder.decodeObject(forKey: Keys.userDefinedAlerts) as! [AKAlert]
        self.init(phoneNumber: phoneNumber, userDefinedAlerts: userDefinedAlerts)
    }
    
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self.phoneNumber, forKey: Keys.phoneNumber)
        aCoder.encode(self.userDefinedAlerts, forKey: Keys.userDefinedAlerts)
    }
}
