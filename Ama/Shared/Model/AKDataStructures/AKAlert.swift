import MapKit
import UIKit

class AKAlert: NSObject, NSCoding {
    // MARK: Constants
    struct Keys {
        static let id = "AK.alert.id"
        static let name = "AK.alert.name"
        static let radius = "AK.alert.radius"
        static let annotation = "AK.alert.annotation"
    }
    
    // MARK: Properties
    let alertID: String
    let alertName: String
    let alertRadius: Double
    let alertView: AKAlertAnnotationView
    let alertAnnotation: AKAlertAnnotation
    
    // MARK: Initializers
    init(alertID: String, alertName: String, alertRadius: Double, alertAnnotation: AKAlertAnnotation) {
        self.alertID = alertID
        self.alertName = alertName
        self.alertRadius = alertRadius
        self.alertAnnotation = alertAnnotation
        
        if let view = (Bundle.main.loadNibNamed("AKAlertAnnotationView", owner: nil, options: nil))?[0] as? AKAlertAnnotationView {
            var newFrame = view.frame
            newFrame.origin = CGPoint(x: -newFrame.size.width/2 + 10, y: -newFrame.size.height - 4)
            view.frame = newFrame
            
            view.id = self.alertID
            view.titleLabel.text = self.alertAnnotation.titleLabel
            view.subtitleLabel.text = self.alertAnnotation.subtitleLabel
            view.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
            
            self.alertView = view
        }
        else {
            self.alertView = AKAlertAnnotationView()
        }
    }
    
    func printObject(_ padding: String = "") -> String {
        let string: NSMutableString = NSMutableString()
        
        string.append("\n")
        string.appendFormat("%@****** ALERT ******\n", padding)
        string.appendFormat("%@>>> ID = %@\n", padding, self.alertID)
        string.appendFormat("%@>>> Name = %@\n", padding, self.alertName)
        string.appendFormat("%@>>> Radius = %f\n", padding, self.alertRadius)
        string.appendFormat("%@>>> View = %@\n", padding, self.alertView)
        string.appendFormat("%@>>> Annotation = %@\n", padding, self.alertAnnotation)
        string.appendFormat("%@****** ALERT ******\n", padding)
        
        return string as String
    }
    
    // MARK: NSCoding Implementation
    required convenience init(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeObject(forKey: Keys.id) as! String
        let name = aDecoder.decodeObject(forKey: Keys.name) as! String
        let radius = aDecoder.decodeDouble(forKey: Keys.radius)
        let annotation = aDecoder.decodeObject(forKey: Keys.annotation) as! AKAlertAnnotation
        
        self.init(alertID: id, alertName: name, alertRadius: radius, alertAnnotation: annotation)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.alertID, forKey: Keys.id)
        aCoder.encode(self.alertName, forKey: Keys.name)
        aCoder.encode(self.alertRadius, forKey: Keys.radius)
        aCoder.encode(self.alertAnnotation, forKey: Keys.annotation)
    }
}
