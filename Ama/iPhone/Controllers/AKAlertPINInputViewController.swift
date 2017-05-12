import UIKit

class AKAlertPINInputViewController: AKCustomViewController, UITextFieldDelegate {
    // MARK: Local Enums
    enum LocalTextField: Int {
        case alertName = 1
    }
    
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
    @IBAction func radioValueChanged(_ sender: Any) {
        // TODO
    }
    
    @IBAction func save(_ sender: Any) {
        let alertName = AKAlertName(inputData: self.nameValue.text!)
        do {
            try alertName.validate()
            try alertName.process()
        }
        catch {
            Func.AKPresentMessageFromError(controller: self, message: "\(error)")
            return
        }
        
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
    
    // MARK: UITextFieldDelegate Implementation
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if range.length + range.location > (textField.text?.characters.count)! {
            return false
        }
        
        let newLen = (textField.text?.characters.count)! + string.characters.count - range.length
        
        switch textField.tag {
        case LocalTextField.alertName.rawValue:
            return newLen > GlobalConstants.AKMaxAlertNameLength ? false : true
        default:
            return newLen > GlobalConstants.AKMaxAlertNameLength ? false : true
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        Func.AKAddDoneButtonKeyboard(textField, controller: self)
        self.currentEditableComponent = textField
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        self.currentEditableComponent = nil
        return true
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
        
        // Delegates
        self.nameValue.delegate = self
        self.nameValue.tag = LocalTextField.alertName.rawValue
    }
}
