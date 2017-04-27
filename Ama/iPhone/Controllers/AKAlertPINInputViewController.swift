import UIKit

class AKAlertPINInputViewController: AKCustomViewController
{
    // MARK: Outlets
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var nameValue: UITextField!
    @IBOutlet weak var radio: UILabel!
    @IBOutlet weak var radioValue: UILabel!
    @IBOutlet weak var radioSlider: UISlider!
    @IBOutlet weak var save: UIButton!
    @IBOutlet weak var discard: UIButton!
    
    // MARK: Actions
    @IBAction func save(_ sender: Any) {
        self.dismissView(executeDismissTask: true)
    }
    
    @IBAction func discard(_ sender: Any) {
        self.dismissView(executeDismissTask: false)
    }
    
    // MARK: AKCustomViewController Overriding
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customSetup()
    }
    
    // MARK: Miscellaneous
    func customSetup() {
        self.configureLookAndFeel = { (controller) -> Void in
            if let controller = controller as? AKAlertPINInputViewController {
                controller.controlsContainer.layer.cornerRadius = GlobalConstants.AKViewCornerRadius
                controller.controlsContainer.layer.masksToBounds = true
                controller.radio.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
                controller.radio.layer.masksToBounds = true
                controller.save.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
                controller.discard.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
            }
        }
        self.setup()
    }
}
