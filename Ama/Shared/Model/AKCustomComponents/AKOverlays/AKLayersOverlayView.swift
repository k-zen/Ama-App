import MapKit
import UIKit

class AKLayersOverlayView: AKCustomView, AKCustomViewProtocol
{
    // MARK: Constants
    struct LocalConstants {
        static let AKViewWidth: CGFloat = 40.0
        static let AKViewHeight: CGFloat = 80.0
    }
    
    // MARK: Properties
    var layersState: Bool = true
    
    // MARK: Outlets
    @IBOutlet weak var layers: UIButton!
    @IBOutlet weak var dropPIN: UIButton!
    
    // MARK: Actions
    @IBAction func viewLayers(_ sender: Any) {
        if let controller = self.controller as? AKHeatMapViewController {
            if self.layersState {
                self.layersState = false
                self.layers.layer.backgroundColor = GlobalConstants.AKDisabledButtonBg.cgColor
                controller.hideLayers()
                controller.hideLegend()
            }
            else {
                self.layersState = true
                self.layers.layer.backgroundColor = GlobalConstants.AKEnabledButtonBg.cgColor
                controller.rainmapObserver()
                controller.showLegend()
            }
        }
    }
    
    @IBAction func dropPIN(_ sender: Any) {
        if let controller = self.controller as? AKHeatMapViewController {
            if Func.AKGetUser().removeAlert(mapView: controller.mapView, id: "", shouldRemoveAll: true) {
                Func.AKPresentMessage(
                    controller: controller,
                    type: .info,
                    message: "Todas las alertas fueron eliminadas...!"
                )
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
        self.dropPIN.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.dropPIN.layer.masksToBounds = true
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
