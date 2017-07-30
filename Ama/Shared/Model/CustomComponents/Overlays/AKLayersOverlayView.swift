import MapKit
import UIKit

class AKLayersOverlayView: AKCustomView, AKCustomViewProtocol {
    // MARK: Constants
    struct LocalConstants {
        static let AKViewWidth: CGFloat = 40.0
        static let AKViewHeight: CGFloat = 40.0
    }
    
    // MARK: Properties
    var layersActive: Bool = true
    
    // MARK: Outlets
    @IBOutlet weak var layers: UIButton!
    
    // MARK: Actions
    @IBAction func viewLayers(_ sender: Any) {
        if let controller = self.controller as? AKDBZMapViewController {
            if self.layersActive {
                self.layersActive = false
                self.layers.layer.backgroundColor = GlobalConstants.AKDisabledButtonBg.cgColor
                controller.hideLayers()
                controller.hideLegend()
                controller.toggleMapZoom(enable: true)
                controller.toggleUserAnnotation(enable: true)
            }
            else {
                self.layersActive = true
                self.layers.layer.backgroundColor = GlobalConstants.AKEnabledButtonBg.cgColor
                controller.dBZMapObserver()
                controller.showLegend()
                controller.toggleMapZoom(enable: false)
                controller.toggleUserAnnotation(enable: false)
            }
        }
    }
    
    // MARK: UIView Overriding
    convenience init() { self.init(frame: CGRect.zero) }
    
    // MARK: Miscellaneous
    override func setup() {
        super.setup()
        
        self.loadComponents()
        self.applyLookAndFeel()
    }
    
    func loadComponents() {}
    
    func applyLookAndFeel() {
        self.layers.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.layers.layer.masksToBounds = true
    }
    
    func draw(container: UIView, coordinates: CGPoint, size: CGSize) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.getView().frame = CGRect(
            x: coordinates.x,
            y: coordinates.y,
            width: LocalConstants.AKViewWidth,
            height: LocalConstants.AKViewHeight
        )
        container.addSubview(self.getView())
        CATransaction.commit()
    }
    
    func resetViewDefaults(controller: AKCustomViewController) {}
}
