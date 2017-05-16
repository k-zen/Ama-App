import CoreLocation
import Foundation
import UIKit

class AKCustomViewController: UIViewController, UIGestureRecognizerDelegate {
    // MARK: Flags
    var shouldCheckLoggedUser: Bool = false
    var inhibitLocationServiceMessage: Bool = true
    var inhibitNotificationMessage: Bool = true
    var shouldAddBlurView: Bool = false
    var inhibitTapGesture: Bool = false
    var inhibitLongPressGesture: Bool = true
    
    // MARK: Operations (Closures)
    let defaultOperationsWhenGesture: (AKCustomViewController, UIGestureRecognizer?) -> Void = { (controller, gesture) -> Void in
        controller.view.endEditing(true)
    }
    var additionalOperationsWhenTaped: (AKCustomViewController, UIGestureRecognizer?) -> Void = { (controller, gesture) -> Void in }
    var additionalOperationsWhenLongPressed: (AKCustomViewController, UIGestureRecognizer?) -> Void = { (controller, gesture) -> Void in }
    var loadData: (AKCustomViewController) -> Void = { (controller) -> Void in }
    var saveData: (AKCustomViewController) -> Void = { (controller) -> Void in }
    var configureLookAndFeel: (AKCustomViewController) -> Void = { (controller) -> Void in }
    
    // MARK: Properties
    var tapGesture: UITapGestureRecognizer?
    var longPressGesture: UILongPressGestureRecognizer?
    var dismissViewCompletionTask: (Void) -> Void = {}
    var currentEditableComponent: UIView?
    var currentScrollContainer: UIScrollView?
    
    // MARK: Overlays
    let messageOverlay = AKMessageView()
    
    // MARK: UIViewController Overriding
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Checks
        if !self.inhibitLocationServiceMessage {
            self.manageAccessToLocationServices()
        }
        if !self.inhibitNotificationMessage {
            self.manageGrantToNotifications()
        }
        if self.shouldCheckLoggedUser && !Func.AKGetUser().isRegistered {
            self.presentView(controller: AKLoginViewController(nibName: "AKLoginView", bundle: nil),
                             taskBeforePresenting: nil,
                             dismissViewCompletionTask: nil
            )
        }
        
        // Persist to disk data each time a view controller appears.
        do {
            NSLog("=> SAVING *MASTER FILE* TO FILE.")
            NSLog("%@", Func.AKDelegate().masterFile.printObject())
            try AKFileUtils.write(GlobalConstants.AKMasterFileName, newData: Func.AKDelegate().masterFile)
        }
        catch {
            NSLog("=> ERROR: \(error)")
        }
        
        self.loadData(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.saveData(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.configureLookAndFeel(self)
    }
    
    // MARK: UIGestureRecognizerDelegate Implementation
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.isKind(of: UITapGestureRecognizer.self) {
            return !self.inhibitTapGesture
        }
        else if gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) {
            return !self.inhibitLongPressGesture
        }
        else {
            return false
        }
    }
    
    // MARK: Initialization
    func setup() {
        // Manage gestures.
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(AKCustomViewController.tap(_:)))
        self.tapGesture?.delegate = self
        self.longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(AKCustomViewController.longPress(_:)))
        self.longPressGesture?.delegate = self
        self.view.addGestureRecognizer(self.tapGesture!)
        self.view.addGestureRecognizer(self.longPressGesture!)
        
        // Miscellaneous
        self.definesPresentationContext = true
        
        // Add BlurView.
        if self.shouldAddBlurView {
            Func.AKAddBlurView(view: self.view, effect: UIBlurEffectStyle.dark)
        }
        
        // Observers.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AKCustomViewController.keyboardWasShow(notification:)),
            name: NSNotification.Name.UIKeyboardDidShow,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AKCustomViewController.keyboardWillBeHidden(notification:)),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
    }
    
    func presentView(controller: AKCustomViewController,
                     taskBeforePresenting: ((_ presenterController: AKCustomViewController, _ presentedController: AKCustomViewController) -> Void)?,
                     dismissViewCompletionTask: ((_ presenterController: AKCustomViewController, _ presentedController: AKCustomViewController) -> Void)?) {
        controller.dismissViewCompletionTask = {
            if dismissViewCompletionTask != nil {
                dismissViewCompletionTask!(self, controller)
            }
        }
        controller.modalTransitionStyle = GlobalConstants.AKDefaultTransitionStyle
        controller.modalPresentationStyle = .overFullScreen
        
        if taskBeforePresenting != nil {
            taskBeforePresenting!(self, controller)
        }
        
        self.present(controller, animated: false, completion: nil)
    }
    
    // MARK: Floating Views
    func showMessage(
        origin: CGPoint,
        type: MessageType,
        message: String,
        animate: Bool,
        completionTask: ((_ controller: AKCustomViewController?) -> Void)?) {
        let origin = Func.AKCenterScreenCoordinate(
            container: self.view,
            width: AKMessageView.LocalConstants.AKViewWidth,
            height: AKMessageView.LocalConstants.AKViewHeight
        )
        
        // Configure the overlay.
        self.messageOverlay.controller = self
        self.messageOverlay.setup()
        self.messageOverlay.draw(container: self.view, coordinates: origin, size: CGSize.zero)
        switch type {
        case .info:
            self.messageOverlay.title.text = MessageType.info.rawValue
            break
        case .warning:
            self.messageOverlay.title.text = MessageType.warning.rawValue
            break
        case .error:
            self.messageOverlay.title.text = MessageType.error.rawValue
            break
        }
        self.messageOverlay.message.text = message
        
        // Expand/Show the overlay.
        self.messageOverlay.expand(
            controller: self,
            expandHeight: AKMessageView.LocalConstants.AKViewHeight,
            animate: animate,
            completionTask: completionTask
        )
    }
    
    func hideMessage(animate: Bool, completionTask: ((_ controller: AKCustomViewController?) -> Void)?) {
        self.messageOverlay.collapse(
            controller: self,
            animate: animate,
            completionTask: completionTask
        )
    }
    
    // MARK: Gesture Handling
    @objc internal func tap(_ gesture: UIGestureRecognizer?) {
        self.defaultOperationsWhenGesture(self, gesture)
        self.additionalOperationsWhenTaped(self, gesture)
    }
    
    @objc internal func longPress(_ gesture: UIGestureRecognizer?) {
        self.defaultOperationsWhenGesture(self, gesture)
        self.additionalOperationsWhenLongPressed(self, gesture)
    }
    
    // MARK: Utility functions
    func manageAccessToLocationServices() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            Func.AKDelegate().locationManager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            NSLog("=> LOCATION SERVICES ==> AUTHORIZED WHEN IN USE")
            Func.AKDelegate().locationManager.startUpdatingLocation()
            Func.AKDelegate().locationManager.startUpdatingHeading()
            break
        case .restricted, .denied:
            // Mark the App as inactive!
            Func.AKDelegate().applicationActive = false
            
            let alertController = UIAlertController(
                title: "Acceso a Ubicación Deshabilitado",
                message: "La App necesita acceso a su ubicación para brindar pronósticos personalizados. Habilítelo en Configuraciones.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { (action) in }))
            alertController.addAction(UIAlertAction(title: "Abrir Configuraciones", style: .default) { (action) in
                if let url = URL(string:UIApplicationOpenSettingsURLString) {
                    Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { () in UIApplication.shared.open(url, options: [:], completionHandler: nil) }
                }})
            self.present(alertController, animated: true, completion: nil)
            break
        default:
            break
        }
    }
    
    func manageGrantToNotifications() {
        Func.AKGetNotificationCenter().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if !granted {
                let alertController = UIAlertController(
                    title: "Acceso a Notificaciones Deshabilitado",
                    message: "Ama necesita permiso para enviarte notificaciones. Habilítelo en Configuraciones.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { (action) in }))
                alertController.addAction(UIAlertAction(title: "Abrir Configuraciones", style: .default) { (action) in
                    if let url = URL(string:UIApplicationOpenSettingsURLString) {
                        Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { () in UIApplication.shared.open(url, options: [:], completionHandler: nil) }
                    }})
                self.present(alertController, animated: true, completion: nil)
            }
            else {
                NSLog("=> INFO: USER HAS AUTHORIZED NOTIFICATIONS.")
            }
        }
    }
    
    func dismissView(executeDismissTask: Bool) {
        if executeDismissTask {
            self.dismiss(animated: true, completion: self.dismissViewCompletionTask)
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: Observers
    func keyboardWasShow(notification: NSNotification) {
        if let info = notification.userInfo, let editableComponent = self.currentEditableComponent {
            if let kbSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size {
                var viewRect = self.view.frame
                viewRect.size.height += (UIScreen.main.bounds.height - viewRect.size.height)
                
                var visibleRect = CGRect(x: 0.0, y: 0.0, width: viewRect.size.width, height: viewRect.size.height)
                visibleRect.size.height -= (kbSize.height + GlobalConstants.AKCloseKeyboardToolbarHeight)
                
                var absoluteComponent = editableComponent.convert(editableComponent.bounds, to: self.view)
                absoluteComponent.origin.y += self.navigationController?.topViewController == self ? 49.0 : 0.0
                
                if !visibleRect.contains(absoluteComponent) {
                    var newPosition = CGPoint(x: 0.0, y: absoluteComponent.origin.y + editableComponent.frame.height)
                    newPosition.y -= visibleRect.size.height
                    
                    self.currentScrollContainer?.setContentOffset(newPosition, animated: true)
                }
            }
        }
    }
    
    func keyboardWillBeHidden(notification: NSNotification) { self.currentScrollContainer?.setContentOffset(CGPoint.zero, animated: true) }
}
