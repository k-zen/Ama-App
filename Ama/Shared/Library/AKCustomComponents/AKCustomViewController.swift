import CoreLocation
import Foundation
import UIKit

/// Base class for all ViewControllers in the App. This custom ViewController
/// implements some basic functionalities that should be present in ViewControllers
/// throughout the App.
///
/// Functionalities:
/// 01. Handle logged in/out events.
/// 02. Handle of **Tap** gestures.
/// 03. Handle of **Pinch** gestures.
/// 04. Handle of **Rotation** gestures.
/// 05. Handle of **Swipe** gestures.
/// 06. Handle of **Pan** gestures.
/// 07. Handle of **Screen Edge Pan** gestures.
/// 08. Handle of **Long Press** gestures.
/// 09. Bottom menu.
/// 10. Handle localisation events.
///
/// - Author: Andreas P. Koenzen <akc@apkc.net>
/// - Copyright: 2017 APKC.net
/// - Date: Jan 5, 2017
class AKCustomViewController: UIViewController, UIGestureRecognizerDelegate
{
    
    // MARK: Flags
    /// Flag to check if a user is logged in/out of the App.
    var shouldCheckLoggedUser: Bool = false
    /// Flag to make location services check on each ViewController.
    /// Default value is **true**, each ViewController must explicitly enable the check.
    var inhibitLocationServiceMessage: Bool = true
    /// Flag to inhibit only the **Tap** gesture.
    var inhibitTapGesture: Bool = false
    /// Flag to inhibit only the **Pinch** gesture.
    var inhibitPinchGesture: Bool = true
    /// Flag to inhibit only the **Rotation** gesture.
    var inhibitRotationGesture: Bool = true
    /// Flag to inhibit only the **Swipe** gesture.
    var inhibitSwipeGesture: Bool = true
    /// Flag to inhibit only the **Pan** gesture.
    var inhibitPanGesture: Bool = true
    /// Flag to inhibit only the **Screen Edge Pan** gesture.
    /// MUST BE ENABLED WITH **inhibitPanGesture** and an edge
    /// must be set.
    var inhibitScreenEdgePanGesture: Bool = true
    /// Flag to inhibit only the **Long Press** gesture.
    var inhibitLongPressGesture: Bool = true
    // MARK: Operations (Closures)
    /// Defaults actions when a gesture event is produced. Not modifiable by child classes.
    let defaultOperationsWhenGesture: (AKCustomViewController, UIGestureRecognizer?) -> Void = { (controller, gesture) -> Void in
        // Always close the keyboard if open.
        controller.view.endEditing(true)
    }
    /// Operations to perform when a **Tap** gesture is detected.
    var additionalOperationsWhenTaped: (UIGestureRecognizer?) -> Void = { (gesture) -> Void in }
    /// Operations to perform when a **Pinch** gesture is detected.
    var additionalOperationsWhenPinched: (UIGestureRecognizer?) -> Void = { (gesture) -> Void in }
    /// Operations to perform when a **Rotation** gesture is detected.
    var additionalOperationsWhenRotated: (UIGestureRecognizer?) -> Void = { (gesture) -> Void in }
    /// Operations to perform when a **Swiped** gesture is detected.
    var additionalOperationsWhenSwiped: (UIGestureRecognizer?) -> Void = { (gesture) -> Void in }
    /// Operations to perform when a **Pan** gesture is detected.
    var additionalOperationsWhenPaned: (UIGestureRecognizer?) -> Void = { (gesture) -> Void in }
    /// Operations to perform when a **Screen Edge Pan** gesture is detected.
    var additionalOperationsWhenScreenEdgePaned: (UIGestureRecognizer?) -> Void = { (gesture) -> Void in }
    /// Operations to perform when a **Long Press** gesture is detected.
    var additionalOperationsWhenLongPressed: (UIGestureRecognizer?) -> Void = { (gesture) -> Void in }
    // MARK: Properties
    var bottomMenu: UIAlertController?
    var tapGesture: UITapGestureRecognizer?
    var pinchGesture: UIPinchGestureRecognizer?
    var rotationGesture: UIRotationGestureRecognizer?
    var swipeGesture: UISwipeGestureRecognizer?
    var panGesture: UIPanGestureRecognizer?
    var screenEdgePanGesture: UIScreenEdgePanGestureRecognizer?
    var longPressGesture: UILongPressGestureRecognizer?
    var dismissViewCompletionTask: (Void) -> Void = {}
    
    // MARK: UIViewController Overriding
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if GlobalConstants.AKDebug {
            NSLog("=> VIEW DID LOAD ON: \(type(of: self))")
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        if GlobalConstants.AKDebug {
            NSLog("=> VIEW DID APPEAR ON: \(type(of: self))")
        }
        // Checks
        if !self.inhibitLocationServiceMessage {
            self.manageAccessToLocationServices()
        }
        if self.shouldCheckLoggedUser {
            self.presentLoginView(dismissViewCompletionTask: { (controller, presentedController) -> Void in controller.shouldCheckLoggedUser = false })
            return
        }
    }
    
    // MARK: UIGestureRecognizerDelegate Implementation
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        if gestureRecognizer.isKind(of: UITapGestureRecognizer.self) {
            return !self.inhibitTapGesture
        }
        else if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
            return !self.inhibitPinchGesture
        }
        else if gestureRecognizer.isKind(of: UIRotationGestureRecognizer.self) {
            return !self.inhibitRotationGesture
        }
        else if gestureRecognizer.isKind(of: UISwipeGestureRecognizer.self) {
            return !self.inhibitSwipeGesture
        }
        else if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
            return !self.inhibitPanGesture
        }
        else if gestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
            return !self.inhibitScreenEdgePanGesture
        }
        else if gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) {
            return !self.inhibitLongPressGesture
        }
        else {
            return false // By default disable all gestures!
        }
    }
    
    // MARK: Initialization
    func setup()
    {
        // Manage gestures.
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(AKCustomViewController.tap(_:)))
        self.tapGesture?.delegate = self
        self.pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(AKCustomViewController.pinch(_:)))
        self.pinchGesture?.delegate = self
        self.rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(AKCustomViewController.rotate(_:)))
        self.rotationGesture?.delegate = self
        self.swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(AKCustomViewController.swipe(_:)))
        self.swipeGesture?.delegate = self
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(AKCustomViewController.pan(_:)))
        self.panGesture?.delegate = self
        self.screenEdgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(AKCustomViewController.screenEdgePan(_:)))
        self.screenEdgePanGesture?.delegate = self
        self.longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(AKCustomViewController.longPress(_:)))
        self.longPressGesture?.delegate = self
        self.view.addGestureRecognizer(self.tapGesture!)
        self.view.addGestureRecognizer(self.pinchGesture!)
        self.view.addGestureRecognizer(self.rotationGesture!)
        self.view.addGestureRecognizer(self.swipeGesture!)
        self.view.addGestureRecognizer(self.panGesture!)
        self.view.addGestureRecognizer(self.screenEdgePanGesture!)
        self.view.addGestureRecognizer(self.longPressGesture!)
        
        // Miscellaneous
        self.definesPresentationContext = true
    }
    
    func setupMenu(_ title: String!, message: String!, type: UIAlertControllerStyle!)
    {
        self.bottomMenu = UIAlertController(title: title, message: message, preferredStyle: type)
    }
    
    func addMenuAction(_ title: String!, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)?)
    {
        if let menu = self.bottomMenu {
            menu.addAction(UIAlertAction(title: title, style: style, handler: handler))
        }
    }
    
    // MARK: Presenters
    func showMenu()
    {
        if let menu = self.bottomMenu {
            self.present(menu, animated: true, completion: nil)
        }
    }
    
    func presentAlerPINInputView(
        coordinates: GeoCoordinate,
        dismissViewCompletionTask: @escaping (AKCustomViewController, AKCustomViewController, GeoCoordinate) -> Void)
    {
        let controller = AKAlertPINInputViewController(nibName: "AKAlertPINInputView", bundle: nil)
        controller.dismissViewCompletionTask = { dismissViewCompletionTask(self, controller, coordinates) }
        controller.view.backgroundColor = UIColor.clear
        controller.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func presentLoginView(dismissViewCompletionTask: @escaping (AKCustomViewController, AKCustomViewController) -> Void)
    {
        let controller = AKLoginViewController(nibName: "AKLoginView", bundle: nil)
        controller.dismissViewCompletionTask = { dismissViewCompletionTask(self, controller) }
        controller.view.backgroundColor = UIColor.clear
        controller.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        
        self.present(controller, animated: true, completion: nil)
    }
    
    // MARK: Gesture Handling
    @objc private func tap(_ gesture: UIGestureRecognizer?)
    {
        NSLog("=> TAP GESTURE DETECTED... DOING SOMETHING...")
        self.defaultOperationsWhenGesture(self, gesture)
        self.additionalOperationsWhenTaped(gesture)
    }
    
    @objc private func pinch(_ gesture: UIGestureRecognizer?)
    {
        NSLog("=> PINCH GESTURE DETECTED... DOING SOMETHING...")
        self.defaultOperationsWhenGesture(self, gesture)
        self.additionalOperationsWhenPinched(gesture)
    }
    
    @objc private func rotate(_ gesture: UIGestureRecognizer?)
    {
        NSLog("=> ROTATION GESTURE DETECTED... DOING SOMETHING...")
        self.defaultOperationsWhenGesture(self, gesture)
        self.additionalOperationsWhenRotated(gesture)
    }
    
    @objc private func swipe(_ gesture: UIGestureRecognizer?)
    {
        NSLog("=> SWIPE GESTURE DETECTED... DOING SOMETHING...")
        self.defaultOperationsWhenGesture(self, gesture)
        self.additionalOperationsWhenSwiped(gesture)
    }
    
    @objc private func pan(_ gesture: UIGestureRecognizer?)
    {
        NSLog("=> PAN GESTURE DETECTED... DOING SOMETHING...")
        self.defaultOperationsWhenGesture(self, gesture)
        self.additionalOperationsWhenPaned(gesture)
    }
    
    @objc private func screenEdgePan(_ gesture: UIGestureRecognizer?)
    {
        NSLog("=> SCREEN EDGE PAN GESTURE DETECTED... DOING SOMETHING...")
        self.defaultOperationsWhenGesture(self, gesture)
        self.additionalOperationsWhenScreenEdgePaned(gesture)
    }
    
    @objc private func longPress(_ gesture: UIGestureRecognizer?)
    {
        NSLog("=> LONG PRESS GESTURE DETECTED... DOING SOMETHING...")
        self.defaultOperationsWhenGesture(self, gesture)
        self.additionalOperationsWhenLongPressed(gesture)
    }
    
    // MARK: Utility functions
    func manageAccessToLocationServices()
    {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            GlobalFunctions.instance(false).AKDelegate().locationManager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            NSLog("=> LOCATION SERVICES ==> AUTHORIZED WHEN IN USE")
            GlobalFunctions.instance(false).AKDelegate().locationManager.startUpdatingLocation()
            GlobalFunctions.instance(false).AKDelegate().locationManager.startUpdatingHeading()
            break
        case .restricted, .denied:
            // Mark the App as inactive!
            GlobalFunctions.instance(false).AKDelegate().applicationActive = false
            
            let alertController = UIAlertController(
                title: "Acceso a Ubicación Deshabilitado",
                message: "La App necesita acceso a su ubicación para brindar pronósticos personalizados. Habilítelo en \"Configuraciones\".",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: { (action) in }))
            alertController.addAction(UIAlertAction(title: "Abrir Configuraciones", style: .default) { (action) in
                if let url = URL(string:UIApplicationOpenSettingsURLString) {
                    GlobalFunctions.instance(false).AKDelay(0.0, task: { () in UIApplication.shared.openURL(url) })
                }})
            self.present(alertController, animated: true, completion: nil)
            break
        default:
            break
        }
    }
    
    func dismissView(executeDismissTask: Bool)
    {
        OperationQueue.main.addOperation {
            if executeDismissTask {
                self.dismiss(animated: true, completion: self.dismissViewCompletionTask)
            }
            else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
