import UIKit

class AKConfigView: AKCustomView, AKCustomViewProtocol {
    // MARK: Constants
    struct LocalConstants {
        static let AKViewWidth: CGFloat = 250.0
        static let AKViewHeight: CGFloat = 100.0
    }
    
    // MARK: Outlets
    @IBOutlet var mainContainer: UIView!
    @IBOutlet weak var notify: UISwitch!
    
    // MARK: Actions
    @IBAction func notify(_ sender: UISwitch, forEvent event: UIEvent) {
        let user = Func.AKGetUser().username
        let pass = Func.AKGetUser().password
        
        Func.AKExecute(mode: .asyncBackground, timeDelay: 0.0) { () -> Void in
            AKBackEndConnector.obtainSessionToken(
                controller: self.controller,
                user: user,
                pass: pass,
                completionTask: { (sessionToken) -> Void in
                    AKWSUtils.makeRESTRequest(
                        controller: nil,
                        endpoint: String(format: "%@/ama/user/update", GlobalConstants.AKAmaServerAddress),
                        httpMethod: "POST",
                        headerValues: [
                            "Content-Type"  : "application/json",
                            "Authorization" : String(format: "Bearer %@", sessionToken)
                        ],
                        bodyValue: String(
                            format: "{\"username\":\"%@\",\"password\":\"%@\",\"alertar\":\"%@\"}",
                            Func.AKGetUser().username,
                            Func.AKGetUser().password,
                            sender.isOn ? "true" : "false"
                        ),
                        showDebugInfo: false,
                        isJSONResponse: false,
                        completionTask: { (json) -> Void in Func.AKGetUser().shouldReceiveAlerts = sender.isOn },
                        failureTask: { (code, message) -> Void in NSLog("=> ERROR: CODE=%i, MESSAGE=%@", code, message ?? "") }
                    ) },
                failureTask: { (code, message) -> Void in }
            )
        }
    }
    
    // MARK: UIView Overriding
    convenience init() { self.init(frame: CGRect.zero) }
    
    // MARK: Miscellaneous
    override func setup() {
        super.inhibitTapGesture = false
        super.setup()
        
        self.loadComponents()
        self.applyLookAndFeel()
        self.addAnimations(expandCollapseHeight: LocalConstants.AKViewHeight)
    }
    
    func loadComponents() {
        self.notify.isOn = Func.AKGetUser().shouldReceiveAlerts
    }
    
    func applyLookAndFeel() {
        self.getView().layer.cornerRadius = GlobalConstants.AKViewCornerRadius
        self.getView().backgroundColor = UIColor.clear
        Func.AKAddBlurView(view: self.getView(), effect: .dark)
    }
    
    func draw(container: UIView, coordinates: CGPoint, size: CGSize) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.getView().frame = CGRect(
            x: coordinates.x,
            y: coordinates.y,
            width: LocalConstants.AKViewWidth,
            height: size.height
        )
        container.addSubview(self.getView())
        CATransaction.commit()
    }
    
    func resetViewDefaults(controller: AKCustomViewController) {}
}
