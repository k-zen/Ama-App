import MapKit
import SVPulsingAnnotationView
import UIKit

class AKAlertsTableViewCell: UITableViewCell, MKMapViewDelegate {
    // MARK: Outlets
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var titleValue: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: UITableViewCell Overriding
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Delegates
        self.mapView.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: MKMapViewDelegate Implementation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: AKUserAnnotation.self) {
            if let custom = annotation as? AKUserAnnotation {
                if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: custom.titleLabel) {
                    return annotationView
                }
                else {
                    let customView = SVPulsingAnnotationView(annotation: annotation, reuseIdentifier: custom.titleLabel)
                    customView.annotationColor = GlobalConstants.AKUserAnnotationBg
                    
                    return customView
                }
            }
            else {
                return nil
            }
        }
        else if annotation.isKind(of: AKAlertAnnotation.self) {
            if let custom = annotation as? AKAlertAnnotation {
                if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: custom.titleLabel) {
                    return annotationView
                }
                else {
                    let customView = SVPulsingAnnotationView(annotation: annotation, reuseIdentifier: custom.titleLabel)
                    customView.annotationColor = GlobalConstants.AKAlertAnnotationBg
                    
                    return customView
                }
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationCanShowCallout annotation: MKAnnotation) -> Bool {
        return false
    }
}
