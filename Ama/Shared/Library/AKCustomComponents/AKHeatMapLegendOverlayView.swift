import UIKit

class AKHeatMapLegendOverlayView: AKCustomView
{
    // MARK: Properties
    let animation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
    var controller: AKCustomViewController?
    
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
        NSLog("=> ENTERING SETUP ON FRAME: AKHeatMapLegendOverlayView")
        
        // Create Legend
        let frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        self.img01.image = UIImage.fromColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C01.rawValue), frame: frame)
        self.img02.image = UIImage.fromColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C02.rawValue), frame: frame)
        self.img03.image = UIImage.fromColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C03.rawValue), frame: frame)
        self.img04.image = UIImage.fromColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C04.rawValue), frame: frame)
        self.img05.image = UIImage.fromColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C05.rawValue), frame: frame)
        self.img06.image = UIImage.fromColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C06.rawValue), frame: frame)
        self.img07.image = UIImage.fromColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C07.rawValue), frame: frame)
        self.img08.image = UIImage.fromColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C08.rawValue), frame: frame)
        self.img09.image = UIImage.fromColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C09.rawValue), frame: frame)
        self.img10.image = UIImage.fromColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C10.rawValue), frame: frame)
        
        self.animation.fromValue = 0.85
        self.animation.toValue = 0.65
        self.animation.duration = 2.0
        self.animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        self.animation.autoreverses = true
        self.animation.repeatCount = 20000
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
