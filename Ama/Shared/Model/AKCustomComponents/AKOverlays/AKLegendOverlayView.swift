import UIKit

class AKLegendOverlayView: AKCustomView, AKCustomViewProtocol
{
    // MARK: Constants
    struct LocalConstants {
        static let AKViewWidth: CGFloat = 49.0
        static let AKViewHeight: CGFloat = 274.0
    }
    
    // MARK: Outlets
    @IBOutlet weak var img01: UIImageView!
    @IBOutlet weak var img02: UIImageView!
    @IBOutlet weak var img03: UIImageView!
    @IBOutlet weak var img04: UIImageView!
    @IBOutlet weak var img05: UIImageView!
    @IBOutlet weak var img06: UIImageView!
    @IBOutlet weak var img07: UIImageView!
    @IBOutlet weak var img08: UIImageView!
    @IBOutlet weak var img09: UIImageView!
    @IBOutlet weak var img10: UIImageView!
    
    // MARK: UIView Overriding
    convenience init() { self.init(frame: CGRect.zero) }
    
    // MARK: Miscellaneous
    override func setup() {
        super.setup()
        
        self.loadComponents()
        self.applyLookAndFeel()
    }
    
    func loadComponents() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 24.0, height: 24.0)
        self.img01.image = UIImage.fromColor(color: Func.AKHexColor(HeatMapColor.C01.rawValue), frame: frame)
        self.img02.image = UIImage.fromColor(color: Func.AKHexColor(HeatMapColor.C02.rawValue), frame: frame)
        self.img03.image = UIImage.fromColor(color: Func.AKHexColor(HeatMapColor.C03.rawValue), frame: frame)
        self.img04.image = UIImage.fromColor(color: Func.AKHexColor(HeatMapColor.C04.rawValue), frame: frame)
        self.img05.image = UIImage.fromColor(color: Func.AKHexColor(HeatMapColor.C05.rawValue), frame: frame)
        self.img06.image = UIImage.fromColor(color: Func.AKHexColor(HeatMapColor.C06.rawValue), frame: frame)
        self.img07.image = UIImage.fromColor(color: Func.AKHexColor(HeatMapColor.C07.rawValue), frame: frame)
        self.img08.image = UIImage.fromColor(color: Func.AKHexColor(HeatMapColor.C08.rawValue), frame: frame)
        self.img09.image = UIImage.fromColor(color: Func.AKHexColor(HeatMapColor.C09.rawValue), frame: frame)
        self.img10.image = UIImage.fromColor(color: Func.AKHexColor(HeatMapColor.C10.rawValue), frame: frame)
    }
    
    func applyLookAndFeel() {}
    
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
