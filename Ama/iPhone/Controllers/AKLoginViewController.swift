import UIKit

class AKLoginViewController: AKCustomViewController, UITextFieldDelegate {
    // MARK: Local Enums
    enum LocalTextField: Int {
        case username = 1
    }
    
    // MARK: Outlets
    @IBOutlet weak var scrollContainer: UIScrollView!
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var usernameValue: UITextField!
    @IBOutlet weak var verify: UIButton!
    
    // MARK: Actions
    @IBAction func login(_ sender: Any) {
        Func.AKExecute(mode: .asyncBackground, timeDelay: 0.0) {
            let username = AKUsername(inputData: self.usernameValue.text!)
            do {
                try username.validate()
                try username.process()
            }
            catch {
                Func.AKPresentMessageFromError(controller: self, message: "\(error)")
                return
            }
            
            AKWSUtils.makeRESTRequest(
                controller: self,
                endpoint: String(format: "%@/ama/user/existe", GlobalConstants.AKAmaServerAddress),
                httpMethod: "POST",
                headerValues: [ "Content-Type" : "application/json" ],
                bodyValue: username.outputData,
                showDebugInfo: true,
                isJSONResponse: false,
                completionTask: { (json) -> Void in
                    // Process the results.
                    if let str = json as? String {
                        if str.caseInsensitiveCompare("false") == ComparisonResult.orderedSame {
                            Func.AKGetUser().username = username.outputData
                            Func.AKGetUser().password = String(format: "%i", arc4random_uniform(100000) + (100000 * (arc4random_uniform(9) + 1)))
                            
                            AKWSUtils.makeRESTRequest(
                                controller: self,
                                endpoint: String(format: "%@/ama/user/insertar", GlobalConstants.AKAmaServerAddress),
                                httpMethod: "POST",
                                headerValues: [ "Content-Type" : "application/json" ],
                                bodyValue: String(
                                    format: "{\"username\":\"%@\",\"password\":\"%@\"}",
                                    Func.AKGetUser().username,
                                    Func.AKGetUser().password
                                ),
                                showDebugInfo: true,
                                isJSONResponse: false,
                                completionTask: { (json) -> Void in
                                    AKWSUtils.makeRESTRequest(
                                        controller: self,
                                        endpoint: String(format: "%@/ama/persona/insertar", GlobalConstants.AKAmaServerAddress),
                                        httpMethod: "POST",
                                        headerValues: [ "Content-Type" : "application/json" ],
                                        bodyValue: String(
                                            format: "{\"username\":\"%@\",\"token\":\"%@\"}",
                                            Func.AKGetUser().username,
                                            Func.AKGetUser().apnsToken
                                        ),
                                        showDebugInfo: true,
                                        isJSONResponse: false,
                                        completionTask: { (json) -> Void in
                                            Func.AKGetUser().registerUser()
                                            self.dismissView(executeDismissTask: true) },
                                        failureTask: { (code, message) -> Void in
                                            switch code {
                                            case ErrorCodes.ConnectionToBackEndError.rawValue:
                                                Func.AKPresentMessage(
                                                    controller: self,
                                                    type: .error,
                                                    message: message ?? "Error genérico."
                                                )
                                                break
                                            case ErrorCodes.InvalidMIMEType.rawValue:
                                                Func.AKPresentMessage(
                                                    controller: self,
                                                    type: .error,
                                                    message: "El servicio devolvió una respuesta inválida. Reportando..."
                                                )
                                                break
                                            case ErrorCodes.JSONProcessingError.rawValue:
                                                Func.AKPresentMessage(
                                                    controller: self,
                                                    type: .error,
                                                    message: "Error procesando respuesta. Reportando..."
                                                )
                                                break
                                            default:
                                                Func.AKPresentMessage(
                                                    controller: self,
                                                    type: .error,
                                                    message: String(format: "%d: Error genérico.", code)
                                                )
                                                break
                                            } }
                                    ) },
                                failureTask: { (code, message) -> Void in
                                    switch code {
                                    case ErrorCodes.ConnectionToBackEndError.rawValue:
                                        Func.AKPresentMessage(
                                            controller: self,
                                            type: .error,
                                            message: message ?? "Error genérico."
                                        )
                                        break
                                    case ErrorCodes.InvalidMIMEType.rawValue:
                                        Func.AKPresentMessage(
                                            controller: self,
                                            type: .error,
                                            message: "El servicio devolvió una respuesta inválida. Reportando..."
                                        )
                                        break
                                    case ErrorCodes.JSONProcessingError.rawValue:
                                        Func.AKPresentMessage(
                                            controller: self,
                                            type: .error,
                                            message: "Error procesando respuesta. Reportando..."
                                        )
                                        break
                                    default:
                                        Func.AKPresentMessage(
                                            controller: self,
                                            type: .error,
                                            message: String(format: "%d: Error genérico.", code)
                                        )
                                        break
                                    } }
                            )
                        }
                        else {
                            Func.AKPresentMessage(
                                controller: self,
                                type: .error,
                                message: "Ese nombre de usuario ya esta registrado. Ingrese otro..."
                            )
                        }
                    } },
                failureTask: { (code, message) -> Void in
                    switch code {
                    case ErrorCodes.ConnectionToBackEndError.rawValue:
                        Func.AKPresentMessage(
                            controller: self,
                            type: .error,
                            message: message ?? "Error genérico."
                        )
                        break
                    case ErrorCodes.InvalidMIMEType.rawValue:
                        Func.AKPresentMessage(
                            controller: self,
                            type: .error,
                            message: "El servicio devolvió una respuesta inválida. Reportando..."
                        )
                        break
                    case ErrorCodes.JSONProcessingError.rawValue:
                        Func.AKPresentMessage(
                            controller: self,
                            type: .error,
                            message: "Error procesando respuesta. Reportando..."
                        )
                        break
                    default:
                        Func.AKPresentMessage(
                            controller: self,
                            type: .error,
                            message: String(format: "%d: Error genérico.", code)
                        )
                        break
                    } }
            )
        }
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
        case LocalTextField.username.rawValue:
            return newLen > GlobalConstants.AKMaxUsernameLength ? false : true
        default:
            return newLen > GlobalConstants.AKMaxUsernameLength ? false : true
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
        self.shouldAddBlurView = true
        self.configureLookAndFeel = { (controller) -> Void in
            if let controller = controller as? AKLoginViewController {
                controller.controlsContainer.layer.cornerRadius = GlobalConstants.AKViewCornerRadius
                controller.usernameValue.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
                controller.verify.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
            }
        }
        self.currentScrollContainer = self.scrollContainer
        self.setup()
        
        // Delegates
        self.usernameValue.delegate = self
        self.usernameValue.tag = LocalTextField.username.rawValue
    }
}
