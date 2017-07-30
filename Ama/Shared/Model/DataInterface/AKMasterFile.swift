import Foundation

class AKMasterFile: NSObject, NSCoding {
    // MARK: Constants
    struct Keys {
        static let user = "AK.user"
    }
    
    // MARK: Properties
    var user: AKUser
    
    // MARK: Initializers
    override init() {
        self.user = AKUser()
    }
    
    init(user: AKUser) {
        self.user = user
    }
    
    // MARK: Utilities
    func printObject(_ padding: String = "") -> String {
        let string: NSMutableString = NSMutableString()
        
        string.append("\n")
        string.appendFormat("%@****** MASTER FILE ******\n", padding)
        string.appendFormat("%@", self.user.printObject("  "))
        string.appendFormat("%@****** MASTER FILE ******\n", padding)
        
        return string as String
    }
    
    // MARK: NSCoding Implementation
    required convenience init(coder aDecoder: NSCoder) {
        let user = aDecoder.decodeObject(forKey: Keys.user) as! AKUser
        self.init(user: user)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.user, forKey: Keys.user)
    }
}
