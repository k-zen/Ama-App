import UIKit

class AKHeatMapAlertsOverlayView: AKCustomView
{
    // MARK: Properties
    let animation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
    var controller: AKCustomViewController?
    
    // MARK: Outlets
    @IBOutlet var container: UIView!
    @IBOutlet weak var dummy1: UIView!
    @IBOutlet weak var tempValue: UILabel!
    @IBOutlet weak var alertValue: UILabel!
    @IBOutlet weak var pauseRefresh: UIButton!
    @IBOutlet weak var location: UILabel!
    
    // MARK: Actions
    @IBAction func pauseRefresh(_ sender: Any)
    {
        if let controller = controller as? AKHeatMapViewController {
            if AKHeatMapUtilityFunctions.stateRefreshTimer(controller) {
                AKHeatMapUtilityFunctions.stopRefreshTimer(controller)
                self.pauseRefresh.setImage(UIImage(named: "0011-024px.png"), for: UIControlState.normal)
                NSLog("=> PAUSED!")
            }
            else {
                AKHeatMapUtilityFunctions.startRefreshTimer(controller)
                self.pauseRefresh.setImage(UIImage(named: "0010-024px.png"), for: UIControlState.normal)
                NSLog("=> RESUMED!")
            }
        }
    }
    
    // MARK: UIView Overriding
    convenience init()
    {
        NSLog("=> DEFAULT init()")
        self.init(frame: CGRect.zero)
    }
    
    override init(frame: CGRect)
    {
        NSLog("=> FRAME init()")
        super.init(frame: frame)
        setup()
    }
    
    required init(coder aDecoder: NSCoder)
    {
        NSLog("=> CODER init()")
        super.init(coder: aDecoder)!
    }
    
    // MARK: Miscellaneous
    func setup()
    {
        NSLog("=> ENTERING SETUP ON FRAME: AKHeatMapAlertsOverlayView")
        
        self.animation.fromValue = 0.75
        self.animation.toValue = 0.50
        self.animation.duration = 1.0
        self.animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        self.animation.autoreverses = true
        self.animation.repeatCount = 20000
        
        // Custom L&F.
        self.pauseRefresh.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.tempValue.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.tempValue.layer.masksToBounds = true
    }
    
    func startAnimation()
    {
        self.customView.layer.add(animation, forKey: "opacity")
    }
    
    func stopAnimation()
    {
        self.customView.layer.removeAllAnimations()
    }
}
