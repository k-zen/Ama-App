import UIKit

class AKTopOverlayView: AKCustomView, AKCustomViewProtocol {
    // MARK: Constants
    struct LocalConstants {
        static let AKViewHeight: CGFloat = 78.0
    }
    
    // MARK: Outlets
    @IBOutlet var container: UIView!
    @IBOutlet weak var dummy1: UIView!
    @IBOutlet weak var userAvatar: UILabel!
    @IBOutlet weak var alertValue: UILabel!
    @IBOutlet weak var pauseRefresh: UIButton!
    @IBOutlet weak var location: UILabel!
    
    // MARK: Actions
    @IBAction func pauseRefresh(_ sender: Any) {
        if let controller = controller as? AKHeatMapViewController {
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
    
    func loadComponents() {
        self.userAvatar.isUserInteractionEnabled = true
        self.userAvatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AKTopOverlayView.viewConfigurations(_:))))
    }
    
    func applyLookAndFeel() {
        self.pauseRefresh.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.userAvatar.layer.cornerRadius = self.userAvatar.frame.width / 2.0
        self.userAvatar.layer.masksToBounds = true
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
    
    // MARK: Actions
    func viewConfigurations(_ gesture: UIGestureRecognizer?) {
        self.controller?.performSegue(withIdentifier: "ViewConfigurationsSegue", sender: self.controller)
    }
}
