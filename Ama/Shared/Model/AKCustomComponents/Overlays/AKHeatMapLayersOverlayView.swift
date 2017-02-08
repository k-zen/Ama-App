import MapKit
import TSMessages
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
        if let controller = self.controller as? AKHeatMapViewController {
            if self.layersState {
                self.layersState = false
                self.layers.layer.backgroundColor = GlobalConstants.AKDisabledButtonBg.cgColor
                AKHeatMapUtilityFunctions.hideLayers(controller)
                AKHeatMapUtilityFunctions.hideLegend(controller)
            }
            else {
                self.layersState = true
                self.layers.layer.backgroundColor = GlobalConstants.AKEnabledButtonBg.cgColor
                controller.rainmapObserver()
                AKHeatMapUtilityFunctions.showLegend(controller)
            }
        }
    }
    
    @IBAction func dropPIN(_ sender: Any)
    {
        if let controller = self.controller as? AKHeatMapViewController {
            if GlobalFunctions.instance(false).AKGetUser().removeAlert(mapView: controller.mapView, id: "", shouldRemoveAll: true) {
                GlobalFunctions.instance(false).AKPresentTopMessage(
                    controller,
                    type: TSMessageNotificationType.success,
                    message: "Todas las alertas fueron eliminadas...!"
                )
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
