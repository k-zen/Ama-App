import UIKit

class AKAlertPINInputViewController: AKCustomViewController
{
    // MARK: Outlets
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var nameValue: UITextField!
    @IBOutlet weak var radio: UILabel!
    @IBOutlet weak var radioValue: UILabel!
    @IBOutlet weak var radioSlider: UISlider!
    @IBOutlet weak var save: UIButton!
    @IBOutlet weak var discard: UIButton!
    
    // MARK: Actions
    @IBAction func save(_ sender: Any)
    {
        self.dismissView(executeDismissTask: true)
        NSLog("=> PIN SAVED!")
    }
    
    @IBAction func discard(_ sender: Any)
    {
        self.dismissView(executeDismissTask: false)
        NSLog("=> PIN DISCARDED!")
    }
    
    // MARK: AKCustomViewController Overriding
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.customSetup()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    // MARK: Miscellaneous
    func customSetup()
    {
        super.setup()
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.translatesAutoresizingMaskIntoConstraints = true
        blurView.frame = self.controlsContainer.bounds
        
        self.controlsContainer.backgroundColor = UIColor.clear
        self.controlsContainer.insertSubview(blurView, at: 0)
        
        // Custom L&F.
        self.controlsContainer.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius * 2.0
        self.controlsContainer.layer.borderWidth = CGFloat(GlobalConstants.AKDefaultBorderThickness * 2.0)
        self.controlsContainer.layer.borderColor = GlobalConstants.AKDefaultViewBorderBg.cgColor
        self.save.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.discard.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.name.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.name.layer.masksToBounds = true
        self.radio.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.radio.layer.masksToBounds = true
        
        GlobalFunctions.instance(false).AKAddBorderDeco(
            self.nameValue,
            color: GlobalConstants.AKDefaultTextfieldBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.bottom
        )
    }
}
