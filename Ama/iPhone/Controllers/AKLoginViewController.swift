import TSMessages
import UIKit

class AKLoginViewController: AKCustomViewController, UITextFieldDelegate
{
    // MARK: Local Enums
    enum LocalTextField: Int {
        case username = 1
    }
    
    // MARK: Outlets
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var usernameValue: UITextField!
    @IBOutlet weak var verify: UIButton!
    
    // MARK: Actions
    @IBAction func login(_ sender: Any)
    {
        GlobalFunctions.instance(false).AKDelay(0.0, isMain: false, task: { Void -> Void in
            let username = AKUsername(inputData: self.usernameValue.text!)
            do {
                try username.validate()
                try username.process()
            }
            catch {
                GlobalFunctions.instance(false).AKPresentMessageFromError("\(error)", controller: self)
                return
            }
            
            AKWSUtils.makeRESTRequest(
                controller: self,
                endpoint: String(format: "%@/ama/user/existe", "http://devel.apkc.net:9001"),
                httpMethod: "POST",
                headerValues: [ "Content-Type" : "application/json" ],
                bodyValue: username.outputData,
                showDebugInfo: true,
                isJSONResponse: false,
                completionTask: { (json) -> Void in
                    // Process the results.
                    if let str = json as? String {
                        if str.caseInsensitiveCompare("false") == ComparisonResult.orderedSame {
                            GlobalFunctions.instance(false).AKGetUser().username = username.outputData
                            GlobalFunctions.instance(false).AKGetUser().password = String(format: "%i", arc4random_uniform(100000) + (100000 * (arc4random_uniform(9) + 1)))
                            
                            AKWSUtils.makeRESTRequest(
                                controller: self,
                                endpoint: String(format: "%@/ama/user/insertar", "http://devel.apkc.net:9001"),
                                httpMethod: "POST",
                                headerValues: [ "Content-Type" : "application/json" ],
                                bodyValue: String(
                                    format: "{\"username\":\"%@\",\"password\":\"%@\"}",
                                    GlobalFunctions.instance(false).AKGetUser().username,
                                    GlobalFunctions.instance(false).AKGetUser().password
                                ),
                                showDebugInfo: true,
                                isJSONResponse: false,
                                completionTask: { (json) -> Void in
                                    AKWSUtils.makeRESTRequest(
                                        controller: self,
                                        endpoint: String(format: "%@/ama/persona/insertar", "http://devel.apkc.net:9001"),
                                        httpMethod: "POST",
                                        headerValues: [ "Content-Type" : "application/json" ],
                                        bodyValue: String(
                                            format: "{\"username\":\"%@\",\"token\":\"%@\"}",
                                            GlobalFunctions.instance(false).AKGetUser().username,
                                            GlobalFunctions.instance(false).AKGetUser().apnsToken
                                        ),
                                        showDebugInfo: true,
                                        isJSONResponse: false,
                                        completionTask: { (json) -> Void in
                                            GlobalFunctions.instance(false).AKGetUser().registerUser()
                                            self.dismissView(executeDismissTask: true) },
                                        failureTask: { (code, message) -> Void in
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
                                            } }
                                    ) },
                                failureTask: { (code, message) -> Void in
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
                                    } }
                            )
                        }
                        else {
                            GlobalFunctions.instance(false).AKPresentTopMessage(
                                self,
                                type: TSMessageNotificationType.error,
                                message: "Ese nombre de usuario ya esta registrado. Ingrese otro..."
                            )
                        }
                    } },
                failureTask: { (code, message) -> Void in
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
                    } }
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
        case LocalTextField.username.rawValue:
            return newLen > GlobalConstants.AKMaxUsernameLength ? false : true
        default:
            return newLen > GlobalConstants.AKMaxUsernameLength ? false : true
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
        self.usernameValue.delegate = self
        self.usernameValue.tag = LocalTextField.username.rawValue
        
        // Custom L&F.
        self.controlsContainer.backgroundColor = UIColor.clear
        self.verify.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        
        GlobalFunctions.instance(false).AKAddBorderDeco(
            self.usernameValue,
            color: GlobalConstants.AKDefaultTextfieldBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.bottom
        )
    }
}
