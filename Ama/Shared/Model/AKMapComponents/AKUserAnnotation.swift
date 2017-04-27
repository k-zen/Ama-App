import MapKit
import UIKit

class AKUserAnnotation: MKPointAnnotation {
    // MARK: Properties
    var titleLabel: String
    
    // MARK: Initializers
    init(titleLabel: String) {
        self.titleLabel = titleLabel
    }
}
