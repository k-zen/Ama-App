import Foundation

class AKUser: NSObject, NSCoding
{
    // MARK: Constants
    struct Keys {
        static let phoneNumber = "AK.phoneNumber"
    }
    
    // MARK: Properties
    static let AKEmptyPhoneNumber = "000000"
    var phoneNumber: String
    
    // MARK: Initializers
    override init()
    {
        self.phoneNumber = AKUser.AKEmptyPhoneNumber
    }
    
    init(phoneNumber: String)
    {
        self.phoneNumber = phoneNumber
        super.init()
    }
    
    // MARK: Utilities
    func printObject(_ padding: String = "") -> String
    {
        let string: NSMutableString = NSMutableString()
        
        string.appendFormat("%@****** USER ******\n", padding)
        string.appendFormat("%@\t>>> Phone Number = %@\n", padding, self.phoneNumber)
        string.appendFormat("%@****** USER ******\n", padding)
        
        return string as String
    }
    
    // MARK: NSCoding Implementation
    required convenience init(coder aDecoder: NSCoder)
    {
        let phoneNumber = aDecoder.decodeObject(forKey: Keys.phoneNumber) as! String
        self.init(phoneNumber: phoneNumber)
    }
    
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self.phoneNumber, forKey: Keys.phoneNumber)
    }
}
