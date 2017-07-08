import Foundation
import MapKit

class AKUser: NSObject, NSCoding {
    // MARK: Constants
    struct Keys {
        static let username = "AK.user.username"
        static let password = "AK.user.password"
        static let shouldReceiveAlerts = "AK.user.shouldReceiveAlerts"
        static let isRegistered = "AK.user.is.registered"
    }
    
    // MARK: Properties
    var username: String
    var password: String
    var shouldReceiveAlerts: Bool
    var isRegistered: Bool
    
    // MARK: Initializers
    override init() {
        self.username = ""
        self.password = ""
        self.shouldReceiveAlerts = true
        self.isRegistered = false
    }
    
    init(username: String, password: String, shouldReceiveAlerts: Bool, isRegistered: Bool) {
        self.username = username
        self.password = password
        self.shouldReceiveAlerts = shouldReceiveAlerts
        self.isRegistered = isRegistered
        
        super.init()
    }
    
    // MARK: Manage registration.
    func registerUser() {
        if !self.isRegistered {
            self.isRegistered = true
        }
    }
    
    // MARK: Utilities
    func printObject(_ padding: String = "") -> String {
        let string: NSMutableString = NSMutableString()
        
        string.appendFormat("%@****** USER ******\n", padding)
        string.appendFormat("%@>>> Username = %@\n", padding, self.username)
        string.appendFormat("%@>>> Password = %@\n", padding, self.password)
        string.appendFormat("%@>>> Should Receive Alerts = %@\n", padding, self.shouldReceiveAlerts ? "YES" : "NO")
        string.appendFormat("%@>>> Is Registered = %@\n", padding, self.isRegistered ? "YES" : "NO")
        string.appendFormat("%@****** USER ******\n", padding)
        
        return string as String
    }
    
    // MARK: NSCoding Implementation
    required convenience init(coder aDecoder: NSCoder) {
        let username = aDecoder.decodeObject(forKey: Keys.username) as! String
        let password = aDecoder.decodeObject(forKey: Keys.password) as! String
        let shouldReceiveAlerts = aDecoder.decodeBool(forKey: Keys.shouldReceiveAlerts)
        let isRegistered = aDecoder.decodeBool(forKey: Keys.isRegistered)
        
        self.init(username: username, password: password, shouldReceiveAlerts: shouldReceiveAlerts, isRegistered: isRegistered)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.username, forKey: Keys.username)
        aCoder.encode(self.password, forKey: Keys.password)
        aCoder.encode(self.shouldReceiveAlerts, forKey: Keys.shouldReceiveAlerts)
        aCoder.encode(self.isRegistered, forKey: Keys.isRegistered)
    }
}
