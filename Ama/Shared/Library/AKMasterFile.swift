import Foundation

class AKMasterFile: NSObject, NSCoding
{
    // MARK: Constants
    struct Keys {
        static let user = "AK.user"
    }
    
    // MARK: Properties
    var user: AKUser
    
    // MARK: Initializers
    override init()
    {
        self.user = AKUser()
    }
    
    init(user: AKUser)
    {
        self.user = user
    }
    
    // MARK: NSCoding Implementation
    required convenience init(coder aDecoder: NSCoder)
    {
        let user = aDecoder.decodeObject(forKey: Keys.user) as! AKUser
        
        if GlobalConstants.AKDebug {
            NSLog("=> ### READING MASTER FILE FROM FILE")
            NSLog("%@", user.printObject("=> "))
            NSLog("=> ### READING MASTER FILE FROM FILE")
        }
        
        self.init(user: user)
    }
    
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self.user, forKey: Keys.user)
        
        if GlobalConstants.AKDebug {
            NSLog("=> ### WRITING MASTER FILE TO FILE")
            NSLog("%@", user.printObject("=> "))
            NSLog("=> ### WRITING MASTER FILE TO FILE")
        }
    }
}
