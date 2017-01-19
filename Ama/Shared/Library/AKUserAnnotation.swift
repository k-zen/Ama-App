import MapKit
import UIKit

class AKUserAnnotation: MKPointAnnotation
{
    var titleLabel: String
    
    init(titleLabel: String)
    {
        self.titleLabel = titleLabel
    }
}
