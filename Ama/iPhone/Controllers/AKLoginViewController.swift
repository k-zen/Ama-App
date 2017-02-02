import TSMessages
import UIKit

class AKLoginViewController: AKCustomViewController, UITextFieldDelegate
{
    // MARK: Local Enums
    enum LocalTextField: Int {
        case phone = 1
    }
    
    // MARK: Outlets
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var phonePrefix: UILabel!
    @IBOutlet weak var phoneValue: UITextField!
    @IBOutlet weak var verify: UIButton!
    
    // MARK: Actions
    @IBAction func login(_ sender: Any)
    {
        GlobalFunctions.instance(false).AKDelay(0.0, isMain: false, task: { Void -> Void in
            let phoneNumber = AKPhoneNumber(inputData: self.phoneValue.text!)
            do {
                try phoneNumber.validate()
                try phoneNumber.process()
            }
            catch {
                GlobalFunctions.instance(false).AKPresentTopMessage(
                    self,
                    type: TSMessageNotificationType.error,
                    message: "\(error)"
                )
                return
            }
            
            let requestBody = self.phoneValue.text ?? "nouser"
            let url = String(format: "%@/ama/user/existe", "http://devel.apkc.net:9001")
            // This closure will be executed if success.
            let completionTask: (Any) -> Void = { (json) -> Void in
                // Process the results.
                if let str = json as? String {
                    if str.caseInsensitiveCompare("true") == ComparisonResult.orderedSame {
                        let requestBody = self.phoneValue.text ?? "nouser"
                        let url = String(format: "%@/ama/persona/suscripcion", "http://devel.apkc.net:9001")
                        // This closure will be executed if success.
                        let completionTask: (Any) -> Void = { (json) -> Void in
                            // Process the results.
                            if let str = json as? String {
                                if str.caseInsensitiveCompare("true") == ComparisonResult.orderedSame {
                                    self.dismissView(executeDismissTask: true)
                                    NSLog("=> LOGGED & SUBSCRIBED IN!")
                                }
                                else {
                                    NSLog("=> LOGGED & NOT SUBSCRIBED IN!")
                                }
                            }
                        }
                        // This closure will be executed if failure.
                        let failureTask: (Int, String?) -> Void = { (code, message) -> Void in
                            switch code {
                            case ErrorCodes.ConnectionToBackEndError.rawValue:
                                GlobalFunctions.instance(false).AKPresentTopMessage(
                                    self,
                                    type: TSMessageNotificationType.error,
                                    message: message ?? "Error genérico."
                                )
                                break
                            case ErrorCodes.InvalidMIMEType.rawValue:
                                GlobalFunctions.instance(false).AKPresentTopMessage(
                                    self,
                                    type: TSMessageNotificationType.error,
                                    message: "El servicio devolvió una respuesta inválida. Reportando..."
                                )
                                break
                            case ErrorCodes.JSONProcessingError.rawValue:
                                GlobalFunctions.instance(false).AKPresentTopMessage(
                                    self,
                                    type: TSMessageNotificationType.error,
                                    message: "Error procesando respuesta. Reportando..."
                                )
                                break
                            default:
                                GlobalFunctions.instance(false).AKPresentTopMessage(
                                    self,
                                    type: TSMessageNotificationType.error,
                                    message: String(format: "%d: Error genérico.", code)
                                )
                                break
                            }
                        }
                        AKWSUtils.makeRESTRequest(
                            controller: self,
                            endpoint: url,
                            httpMethod: "POST",
                            headerValues: [ "Content-Type" : "application/json" ],
                            bodyValue: requestBody,
                            showDebugInfo: true,
                            isJSONResponse: false,
                            completionTask: { (jsonDocument) -> Void in completionTask(jsonDocument) },
                            failureTask: { (code, message) -> Void in failureTask(code, message) }
                        )
                    }
                    else {
                        NSLog("=> NOT LOGGED IN!")
                    }
                }
            }
            // This closure will be executed if failure.
            let failureTask: (Int, String?) -> Void = { (code, message) -> Void in
                switch code {
                case ErrorCodes.ConnectionToBackEndError.rawValue:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        self,
                        type: TSMessageNotificationType.error,
                        message: message ?? "Error genérico."
                    )
                    break
                case ErrorCodes.InvalidMIMEType.rawValue:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        self,
                        type: TSMessageNotificationType.error,
                        message: "El servicio devolvió una respuesta inválida. Reportando..."
                    )
                    break
                case ErrorCodes.JSONProcessingError.rawValue:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        self,
                        type: TSMessageNotificationType.error,
                        message: "Error procesando respuesta. Reportando..."
                    )
                    break
                default:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        self,
                        type: TSMessageNotificationType.error,
                        message: String(format: "%d: Error genérico.", code)
                    )
                    break
                }
            }
            AKWSUtils.makeRESTRequest(
                controller: self,
                endpoint: url,
                httpMethod: "POST",
                headerValues: [ "Content-Type" : "application/json" ],
                bodyValue: requestBody,
                showDebugInfo: true,
                isJSONResponse: false,
                completionTask: { (jsonDocument) -> Void in completionTask(jsonDocument) },
                failureTask: { (code, message) -> Void in failureTask(code, message) }
            )
        })
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
    
    // MARK: UITextFieldDelegate Implementation
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        if range.length + range.location > (textField.text?.characters.count)! {
            return false
        }
        
        let newLen = (textField.text?.characters.count)! + string.characters.count - range.length
        
        switch textField.tag {
        case LocalTextField.phone.rawValue:
            return newLen > GlobalConstants.AKMaxPhoneNumberLength ? false : true
        default:
            return newLen > GlobalConstants.AKMaxPhoneNumberLength ? false : true
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        GlobalFunctions.instance(false).AKAddDoneButtonKeyboard(textField, controller: self)
        
        switch textField.tag {
        default:
            return true
        }
    }
    
    // MARK: Miscellaneous
    func customSetup()
    {
        super.setup()
        
        // Set Delegator.
        self.phoneValue.delegate = self
        self.phoneValue.tag = LocalTextField.phone.rawValue
        
        // Custom L&F.
        self.controlsContainer.backgroundColor = UIColor.clear
        self.verify.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.phonePrefix.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.phonePrefix.layer.masksToBounds = true
        
        GlobalFunctions.instance(false).AKAddBorderDeco(
            self.phoneValue,
            color: GlobalConstants.AKDefaultTextfieldBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.bottom
        )
    }
}
