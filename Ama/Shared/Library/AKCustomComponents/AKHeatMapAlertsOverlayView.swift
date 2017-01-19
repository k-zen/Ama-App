import UIKit

class AKHeatMapAlertsOverlayView: AKCustomView
{
    // MARK: Properties
    let animation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
    var controller: AKCustomViewController?
    
    // MARK: Outlets
    @IBOutlet var container: UIView!
    @IBOutlet weak var alertValue: UILabel!
    @IBOutlet weak var pauseRefresh: UIButton!
    
    // MARK: Actions
    @IBAction func pauseRefresh(_ sender: Any)
    {
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
