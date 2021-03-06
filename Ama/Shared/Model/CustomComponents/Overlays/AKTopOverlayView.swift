import UIKit

class AKTopOverlayView: AKCustomView, AKCustomViewProtocol {
    // MARK: Constants
    struct LocalConstants {
        static let AKViewHeight: CGFloat = 100.0
    }
    
    // MARK: Outlets
    @IBOutlet var container: UIView!
    @IBOutlet weak var dummy1: UIView!
    @IBOutlet weak var config: UIButton!
    @IBOutlet weak var alertValue: UILabel!
    @IBOutlet weak var pauseRefresh: UIButton!
    @IBOutlet weak var lastUpdate: UILabel!
    @IBOutlet weak var stormCluster: UILabel!
    
    // MARK: Actions
    @IBAction func config(_ sender: Any) {
        if let controller = self.controller as? AKDBZMapViewController {
            controller.showConfig(
                origin: CGPoint.zero,
                animate: true,
                completionTask: nil
            )
        }
    }
    
    @IBAction func pauseRefresh(_ sender: Any) {
        if let controller = self.controller as? AKDBZMapViewController {
            if controller.stateRefreshTimer() {
                controller.stopRefreshTimer()
                self.pauseRefresh.setImage(UIImage(named: "0011-024px.png"), for: UIControlState.normal)
                NSLog("=> PAUSED!")
            }
            else {
                controller.startRefreshTimer()
                self.pauseRefresh.setImage(UIImage(named: "0010-024px.png"), for: UIControlState.normal)
                NSLog("=> RESUMED!")
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
        self.pauseRefresh.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.config.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
    }
    
    func draw(container: UIView, coordinates: CGPoint, size: CGSize) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.getView().frame = CGRect(
            x: coordinates.x,
            y: coordinates.y,
            width: size.width,
            height: LocalConstants.AKViewHeight
        )
        container.addSubview(self.getView())
        CATransaction.commit()
    }
    
    func resetViewDefaults(controller: AKCustomViewController) {}
}
