import UIKit

class AKHeatMapLayersOverlayView: AKCustomView
{
    // MARK: Properties
    let animation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
    var layersState: Bool = true
    var controller: AKCustomViewController?
    
    // MARK: Outlets
    @IBOutlet weak var layers: UIButton!
    @IBOutlet weak var dropPIN: UIButton!
    
    // MARK: Actions
    @IBAction func viewLayers(_ sender: Any)
    {
        if let c: AKHeatMapViewController = self.controller as! AKHeatMapViewController? {
            if self.layersState {
                c.hideLayers()
                self.layersState = false
                self.layers.layer.backgroundColor = GlobalConstants.AKDisabledButtonBg.cgColor
            }
            else {
                c.loadRainMap(c, nil)
                self.layersState = true
                self.layers.layer.backgroundColor = GlobalConstants.AKEnabledButtonBg.cgColor
            }
        }
    }
    
    @IBAction func dropPIN(_ sender: Any)
    {
        NSLog("=> PIN DROP.")
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
        NSLog("=> ENTERING SETUP ON FRAME: AKHeatMapLayersOverlayView")
        
        self.animation.fromValue = 0.85
        self.animation.toValue = 0.65
        self.animation.duration = 2.0
        self.animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        self.animation.autoreverses = true
        self.animation.repeatCount = 20000
        
        // Custom L&F.
        self.layers.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.layers.layer.masksToBounds = true
        self.dropPIN.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.dropPIN.layer.masksToBounds = true
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
