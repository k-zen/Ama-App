import UIKit

class AKProgressOverlayView: AKCustomView, AKCustomViewProtocol {
    // MARK: Constants
    struct LocalConstants {
        static let AKViewHeight: CGFloat = 20.0
    }
    
    // MARK: Outlets
    @IBOutlet var container: UIView!
    @IBOutlet weak var progress: UIProgressView!
    
    // MARK: UIView Overriding
    convenience init() { self.init(frame: CGRect.zero) }
    
    // MARK: Miscellaneous
    override func setup() {
        super.setup()
        
        self.loadComponents()
        self.applyLookAndFeel()
    }
    
    func loadComponents() {}
    
    func applyLookAndFeel() {}
    
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
