import TSMessages
import UIKit

class AKLoginViewController: AKCustomViewController
{
    // MARK: Outlets
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var user: UILabel!
    @IBOutlet weak var userValue: UITextField!
    @IBOutlet weak var pass: UILabel!
    @IBOutlet weak var passValue: UITextField!
    @IBOutlet weak var login: UIButton!
    
    // MARK: Actions
    @IBAction func login(_ sender: Any)
    {
        GlobalFunctions.instance(false).AKDelay(0.0, isMain: false, task: { Void -> Void in
            let requestBody = self.userValue.text ?? "nouser"
            let url = String(format: "%@/ama/user/existe", "http://devel.apkc.net:9001")
            // This closure will be executed if success.
            let completionTask: (Any) -> Void = { (json) -> Void in
                // Process the results.
                if let str = json as? String {
                    if str.caseInsensitiveCompare("true") == ComparisonResult.orderedSame {
                        let requestBody = self.userValue.text ?? "nouser"
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
        self.login.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.user.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.user.layer.masksToBounds = true
        self.pass.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        self.pass.layer.masksToBounds = true
        
        GlobalFunctions.instance(false).AKAddBorderDeco(
            self.userValue,
            color: GlobalConstants.AKDefaultTextfieldBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.bottom
        )
        GlobalFunctions.instance(false).AKAddBorderDeco(
            self.passValue,
            color: GlobalConstants.AKDefaultTextfieldBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.bottom
        )
    }
}
