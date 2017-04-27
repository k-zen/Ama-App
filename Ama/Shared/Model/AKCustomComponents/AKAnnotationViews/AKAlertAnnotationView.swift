import MapKit
import UIKit

class AKAlertAnnotationView: MKAnnotationView {
    // MARK: Properties
    var id: String?
    
    // MARK: Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
}
