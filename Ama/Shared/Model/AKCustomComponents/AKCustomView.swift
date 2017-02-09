import UIKit

class AKCustomView: UIView
{
    // MARK: Properties
    var customView: UIView = UIView()
    
    // MARK: UIView Overriding
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        // Load NIB file.
        if let nib = Bundle.main.loadNibNamed("\(type(of: self))", owner: self, options: nil)?.first as? UIView {
            self.customView = nib
            self.customView.isUserInteractionEnabled = true
            self.addSubview(self.customView)
            
            NSLog("=> INFO: INITIALIZING CUSTOM CLASS *\(type(of: self))* VIA init(frame:)...")
        }
        else {
            NSLog("=> ERROR: FAILED TO INITIALIZE CUSTOM CLASS *\(type(of: self))* VIA init(frame:)...")
        }
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        // Load NIB file.
        if let nib = Bundle.main.loadNibNamed("\(type(of: self))", owner: self, options: nil)?.first as? UIView {
            self.customView = nib
            self.customView.isUserInteractionEnabled = true
            self.addSubview(self.customView)
            
            NSLog("=> INFO: INITIALIZING CUSTOM CLASS *\(type(of: self))* VIA init(coder:)...")
        }
        else {
            NSLog("=> ERROR: FAILED TO INITIALIZE CUSTOM CLASS *\(type(of: self))* VIA init(coder:)...")
        }
    }
}
