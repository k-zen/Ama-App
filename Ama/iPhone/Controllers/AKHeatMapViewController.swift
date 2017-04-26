import CoreLocation
import Foundation
import MapKit
import UIKit

class AKHeatMapViewController: AKCustomViewController, MKMapViewDelegate {
    // MARK: Properties
    // Flags
    let addUserPin = true
    // Overlay Controllers
    let layersOverlay = AKLayersOverlayView()
    let legendOverlay = AKLegendOverlayView()
    let progressOverlay = AKProgressOverlayView()
    let topOverlay = AKTopOverlayView()
    // Custom Annotations
    var userAnnotation: AKUserAnnotation?
    // Custom Annotation Views
    var userAnnotationView: AKUserAnnotationView?
    // Timers
    var refreshTimer: Timer?
    // Misc
    var geoCoordinate: GeoCoordinate?
    
    // MARK: Closures
    let loadRainMap: (_ controller: AKHeatMapViewController, _ progress: UIProgressView?, _ caller: UIButton) -> Void = { (controller, progress, caller) -> Void in
        Func.AKPrintTimeElapsedWhenRunningCode(title: "Load_HeatMap", operation: { (Void) -> Void in
            if !controller.layersOverlay.layersState {
                return
            }
            
            caller.isEnabled = false
            UIView.animate(withDuration: 1.0, animations: { (Void) -> Void in
                caller.backgroundColor = GlobalConstants.AKDisabledButtonBg
            })
            
            progress?.setProgress(0.25, animated: true)
            
            controller.clearMap()
            
            Func.AKDelay(2.0, task: { (Void) -> Void in
                Func.AKCenterMapOnLocation(
                    mapView: controller.mapView,
                    location: Func.AKDelegate().currentPosition ?? GlobalConstants.AKRadarOrigin,
                    zoomLevel: GlobalConstants.AKDefaultZoomLevel
                )
            })
            
            let rainfallPoints = NSMutableArray()
            let requestBody = ""
            let url = String(format: "%@/ama/ultimodato", GlobalConstants.AKAmaServerAddress)
            let completionTask: (Any) -> Void = { (json) -> Void in
                Func.AKExecuteInMainThread(mode: .async) { (Void) -> Void in
                    progress?.setProgress(0.50, animated: true)
                }
                
                if let dictionary = json as? JSONObject {
                    if let array = dictionary["arrayDatos"] as? JSONObjectArray {
                        for element in array {
                            if let e = element as? JSONObject {
                                let intensity = e["intensidad"] as? RainIntensity ?? GlobalConstants.AKInvalidIntensity
                                let coordinates = e["coordenadas"] as? JSONObjectStringArray ?? []
                                for coordinate in coordinates {
                                    let lat = CLLocationDegrees(coordinate.components(separatedBy: ":")[0])!
                                    let lon = CLLocationDegrees(coordinate.components(separatedBy: ":")[1])!
                                    let location = GeoCoordinate(latitude: lat, longitude: lon)
                                    
                                    rainfallPoints.add(AKRainfallPoint(center: location, intensity: intensity))
                                }
                                
                                Func.AKExecuteInMainThread(mode: .async) { (Void) -> Void in
                                    progress?.setProgress(0.75, animated: true)
                                }
                            }
                        }
                        
                        Func.AKExecuteInMainThread(mode: .async) { (Void) -> Void in
                            controller.mapView.add(AKRainOverlay(rainfallPoints: rainfallPoints), level: MKOverlayLevel.aboveRoads)
                            progress?.setProgress(1.0, animated: true)
                        }
                    }
                }
                
                Func.AKExecuteInMainThread(mode: .async) { (Void) -> Void in
                    controller.locationObserver()
                }
                
                Func.AKDelay(2.0, task: { (Void) -> Void in
                    progress?.setProgress(0.0, animated: false)
                    caller.isEnabled = true
                    UIView.animate(withDuration: 1.0, animations: { (Void) -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                })
            }
            let failureTask: (Int, String) -> Void = { (code, message) -> Void in
                switch code {
                case ErrorCodes.ConnectionToBackEndError.rawValue:
                    Func.AKPresentMessage(
                        controller: controller,
                        type: .error,
                        message: message
                    )
                    break
                case ErrorCodes.InvalidMIMEType.rawValue:
                    Func.AKPresentMessage(
                        controller: controller,
                        type: .error,
                        message: "El servicio devolvió una respuesta inválida. Reportando..."
                    )
                    break
                case ErrorCodes.JSONProcessingError.rawValue:
                    Func.AKPresentMessage(
                        controller: controller,
                        type: .error,
                        message: "Error procesando respuesta. Reportando..."
                    )
                    break
                default:
                    Func.AKPresentMessage(
                        controller: controller,
                        type: .error,
                        message: String(format: "%d: Error genérico.", code)
                    )
                    break
                }
                
                Func.AKDelay(2.0, task: { (Void) -> Void in
                    progress?.setProgress(0.0, animated: false)
                    caller.isEnabled = true
                    UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                })
            }
            
            Func.AKDelay(0.0, isMain: false, task: { Void -> Void in
                AKWSUtils.makeRESTRequest(
                    controller: controller,
                    endpoint: url,
                    httpMethod: "GET",
                    headerValues: [ "Content-Type" : "application/json" ],
                    bodyValue: requestBody,
                    completionTask: { (jsonDocument) -> Void in completionTask(jsonDocument) },
                    failureTask: { (code, message) -> Void in failureTask(code, message!) }
                )
            })
        })
    }
    let updateLabels: (AKHeatMapViewController) -> Void = { (controller) -> Void in
        Func.AKDelay(0.0, isMain: false, task: {
            // TODO: Add support for querying temperature via Apple here.
        })
        
        if Func.AKDelegate().applicationActive {
            UIView.transition(
                with: controller.topOverlay.alertValue,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: {
                    // TODO: Add function here to detect the state of weather and issue a label in 3 possible categories.
                    controller.topOverlay.alertValue.text = "Lluvioso" },
                completion: nil
            )
        }
        else {
            UIView.transition(
                with: controller.topOverlay.alertValue,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: {
                    controller.topOverlay.alertValue.text = "Deshabilitado" },
                completion: nil
            )
        }
        
        if GlobalConstants.AKDebug {
            NSLog("=> INFO: NUMBER OF OVERLAYS => %d", controller.mapView.overlays.count)
        }
        
        Func.AKDelay(2.0, task: {
            CLGeocoder().reverseGeocodeLocation(
                CLLocation(
                    latitude: Func.AKDelegate().currentPosition?.latitude ?? kCLLocationCoordinate2DInvalid.latitude,
                    longitude: Func.AKDelegate().currentPosition?.longitude ?? kCLLocationCoordinate2DInvalid.longitude
                ),
                completionHandler: { (placemarks, error) in
                    if error == nil {
                        if let p = placemarks {
                            if p.count > 0 {
                                UIView.transition(
                                    with: controller.topOverlay.location,
                                    duration: 1.00,
                                    options: [UIViewAnimationOptions.transitionCrossDissolve],
                                    animations: {
                                        if let lines: Array<String> = p[0].addressDictionary?["FormattedAddressLines"] as? Array<String> {
                                            let placeString = lines.joined(separator: ", ")
                                            controller.topOverlay.location.text = String(
                                                format: "%@", placeString
                                            )
                                        }
                                        else {
                                            controller.topOverlay.location.text = String(
                                                format: "%@, %@", p[0].locality ?? "---", p[0].country ?? "---"
                                            )
                                        } },
                                    completion: nil
                                )
                            }
                        }
                    } }
            )
        })
    }
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: AKCustomViewController Overriding
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customSetup()
    }
    
    // MARK: MKMapViewDelegate Implementation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: AKUserAnnotation.self) {
            if let custom = annotation as? AKUserAnnotation {
                if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: custom.titleLabel) {
                    return annotationView
                }
                else {
                    let customView = MKAnnotationView(annotation: annotation, reuseIdentifier: custom.titleLabel)
                    customView.canShowCallout = false
                    customView.layer.backgroundColor = UIColor.clear.cgColor
                    customView.layer.cornerRadius = 6.0
                    customView.layer.borderWidth = 0.0
                    customView.layer.masksToBounds = true
                    customView.image = Func.AKCircleImageWithRadius(
                        8,
                        strokeColor: UIColor.white,
                        strokeAlpha: 1.0,
                        fillColor: GlobalConstants.AKUserAnnotationBg,
                        fillAlpha: 1.0,
                        lineWidth: CGFloat(1.4)
                    )
                    customView.clipsToBounds = false
                    
                    return customView
                }
            }
            else {
                return nil
            }
        }
        else if annotation.isKind(of: AKAlertAnnotation.self) {
            if let custom = annotation as? AKAlertAnnotation {
                if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: custom.titleLabel) {
                    return annotationView
                }
                else {
                    let customView = MKAnnotationView(annotation: annotation, reuseIdentifier: custom.titleLabel)
                    customView.canShowCallout = false
                    customView.layer.backgroundColor = UIColor.clear.cgColor
                    customView.layer.cornerRadius = 6.0
                    customView.layer.borderWidth = 0.0
                    customView.layer.masksToBounds = true
                    customView.image = Func.AKCircleImageWithRadius(
                        8,
                        strokeColor: UIColor.white,
                        strokeAlpha: 1.0,
                        fillColor: GlobalConstants.AKAlertAnnotationBg,
                        fillAlpha: 1.0,
                        lineWidth: CGFloat(1.4)
                    )
                    customView.clipsToBounds = false
                    
                    return customView
                }
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: AKRainOverlay.self) {
            let ol = overlay as! AKRainOverlay
            return AKRainOverlayRenderer(overlay: overlay, rainfallPoints: ol.rainfallPoints as! [AKRainfallPoint])
        }
        else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationCanShowCallout annotation: MKAnnotation) -> Bool {
        if annotation.isKind(of: AKUserAnnotation.self) {
            return true
        }
        else if annotation.isKind(of: AKAlertAnnotation.self) {
            return true
        }
        else {
            return false
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if (view.annotation?.isKind(of: AKUserAnnotation.self))! {
            if let annotation = view.annotation as? AKUserAnnotation {
                if let v = (Bundle.main.loadNibNamed("AKUserAnnotationView", owner: self, options: nil))?[0] as? AKUserAnnotationView {
                    var newFrame = v.frame
                    newFrame.origin = CGPoint(x: -newFrame.size.width/2 + 10.0, y: -newFrame.size.height - 4.0)
                    v.frame = newFrame
                    
                    v.titleLabel.text = annotation.titleLabel
                    v.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
                    // v.layer.borderWidth = CGFloat(GlobalConstants.AKDefaultBorderThickness)
                    // v.layer.borderColor = GlobalConstants.AKDefaultViewBorderBg.cgColor
                    
                    self.userAnnotationView = v
                    
                    UIView.transition(
                        with: view,
                        duration: 1.0,
                        options: [UIViewAnimationOptions.transitionCrossDissolve],
                        animations: { view.addSubview(self.userAnnotationView!) },
                        completion: nil
                    )
                }
            }
        }
        else if (view.annotation?.isKind(of: AKAlertAnnotation.self))! {
            if let annotation = view.annotation as? AKAlertAnnotation {
                if let alert = Func.AKGetUser().findAlert(id: annotation.id) {
                    UIView.transition(
                        with: view,
                        duration: 1.0,
                        options: [UIViewAnimationOptions.transitionCrossDissolve],
                        animations: { view.addSubview(alert.alertView) },
                        completion: nil
                    )
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if (view.annotation?.isKind(of: AKUserAnnotation.self))! {
            self.userAnnotationView?.removeFromSuperview()
        }
        else if (view.annotation?.isKind(of: AKAlertAnnotation.self))! {
            if let annotation = view.annotation as? AKAlertAnnotation {
                if let alert = Func.AKGetUser().findAlert(id: annotation.id) {
                    alert.alertView.removeFromSuperview()
                }
            }
        }
    }
    
    // MARK: Observers
    func locationObserver() {
        Func.AKExecuteInMainThread(mode: .async) { (Void) -> Void in
            if Func.AKDelegate().applicationActive {
                let coordinate = Func.AKDelegate().currentPosition ?? kCLLocationCoordinate2DInvalid
                
                if self.addUserPin {
                    if self.userAnnotation != nil {
                        self.mapView.deselectAnnotation(self.userAnnotation!, animated: true)
                        self.mapView.removeAnnotation(self.userAnnotation!)
                    }
                    
                    self.userAnnotation = AKUserAnnotation(titleLabel: "Mi ubicación ahora...")
                    self.userAnnotation?.coordinate = coordinate
                    self.mapView.addAnnotation(self.userAnnotation!)
                    // self.mapView.selectAnnotation(self.userAnnotation!, animated: true)
                }
                
                self.updateLabels(self)
            }
        }
    }
    
    func rainmapObserver() {
        self.loadRainMap(self, self.progressOverlay.progress, self.layersOverlay.layers)
    }
    
    // MARK: Miscellaneous
    func customSetup() {
        self.shouldCheckLoggedUser = true
        self.inhibitLocationServiceMessage = false
        self.inhibitTapGesture = true
        self.inhibitLongPressGesture = false
        self.additionalOperationsWhenLongPressed = { (controller, gesture) -> Void in
            if let controller = controller as? AKHeatMapViewController, let g = gesture as? UILongPressGestureRecognizer {
                if g.state == UIGestureRecognizerState.ended {
                    if Func.AKGetUser().countAlerts() >= GlobalConstants.AKMaxUserDefinedAlerts {
                        Func.AKPresentMessage(
                            controller: controller,
                            type: .error,
                            message: "Has alcanzado el límite de alertas!"
                        )
                        return
                    }
                    
                    controller.geoCoordinate = controller.mapView.convert(g.location(in: controller.mapView), toCoordinateFrom: controller.mapView)
                    controller.presentView(controller: AKAlertPINInputViewController(nibName: "AKAlertPINInputView", bundle: nil),
                                           taskBeforePresenting: nil,
                                           dismissViewCompletionTask: { (presenterController, presentedController) -> Void in
                                            if let presenterController = presenterController as? AKHeatMapViewController, let presentedController = presentedController as? AKAlertPINInputViewController {
                                                let id = UUID().uuidString
                                                let name = presentedController.nameValue.text ?? "Sin Nombre"
                                                let radius = presentedController.radioSlider.value * 10.0
                                                let title = name
                                                let subtitle = String(format: "Radio de : %.1fkm", radius)
                                                
                                                let annotation = AKAlertAnnotation(id: id, titleLabel: title, subtitleLabel: subtitle, location: presenterController.geoCoordinate ?? kCLLocationCoordinate2DInvalid)
                                                
                                                let alert = Alert(alertID: id, alertName: name, alertRadius: Double(radius), alertAnnotation: annotation)
                                                
                                                Func.AKGetUser().addAlert(alert: alert)
                                                
                                                presenterController.mapView.addAnnotation(alert.alertAnnotation)
                                                presenterController.mapView.selectAnnotation(annotation, animated: true)
                                            }
                    })
                }
            }
        }
        self.loadData = { (controller) -> Void in
            if let controller = controller as? AKHeatMapViewController {
                // Custom notifications.
                NotificationCenter.default.addObserver(
                    controller,
                    selector: #selector(AKHeatMapViewController.locationObserver),
                    name: NSNotification.Name(GlobalConstants.AKLocationUpdateNotificationName),
                    object: nil
                )
                
                // Configure map.
                controller.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                controller.mapView.userTrackingMode = MKUserTrackingMode.none
                
                // Load all user defined alerts.
                Func.AKDelay(2.0, task: {
                    for alert in Func.AKGetUser().userDefinedAlerts {
                        controller.mapView.addAnnotation(alert.alertAnnotation)
                        controller.mapView.selectAnnotation(alert.alertAnnotation, animated: true)
                    }
                })
                
                // Add RainMap
                controller.startRefreshTimer()
                
                controller.addDefaultViewOverlays()
                Func.AKCenterMapOnLocation(
                    mapView: controller.mapView,
                    location: Func.AKDelegate().currentPosition ?? GlobalConstants.AKRadarOrigin,
                    zoomLevel: GlobalConstants.AKDefaultZoomLevel
                )
                controller.updateLabels(self)
            }
        }
        self.setup()
        
        // Delegates
        self.mapView.delegate = self
    }
    
    // MARK: Utilities
    func clearMap() {
        if self.mapView.overlays.count > 0 {
            let overlaysToRemove = self.mapView.overlays.filter({ (overlay) -> Bool in
                return true
            })
            self.mapView.removeOverlays(overlaysToRemove)
        }
        
        if GlobalConstants.AKDebug {
            NSLog("=> INFO: NUMBER OF OVERLAYS => %d", self.mapView.overlays.count)
        }
    }
    
    func hideLayers() {
        if self.mapView.overlays.count > 0 {
            let overlaysToRemove = self.mapView.overlays.filter({ (overlay) -> Bool in
                if overlay.isKind(of: AKRainOverlay.self) {
                    return true
                }
                else {
                    return false
                }
            })
            self.mapView.removeOverlays(overlaysToRemove)
        }
        
        if GlobalConstants.AKDebug {
            NSLog("=> INFO: NUMBER OF OVERLAYS => %d", self.mapView.overlays.count)
        }
    }
    
    func addDefaultViewOverlays() {
        self.layersOverlay.controller = self
        self.layersOverlay.setup()
        self.layersOverlay.draw(
            container: self.mapView,
            coordinates: CGPoint(
                x: (self.mapView.bounds.width - AKLayersOverlayView.LocalConstants.AKViewWidth),
                y: (self.mapView.bounds.height / 2.0) - (AKLayersOverlayView.LocalConstants.AKViewHeight / 2.0)
            ),
            size: CGSize.zero
        )
        
        self.legendOverlay.controller = self
        self.legendOverlay.setup()
        self.legendOverlay.draw(
            container: self.mapView,
            coordinates: CGPoint(
                x: 0.0,
                y: (self.mapView.bounds.height / 2.0) - (AKLegendOverlayView.LocalConstants.AKViewHeight / 2.0)
            ),
            size: CGSize.zero
        )
        
        self.progressOverlay.controller = self
        self.progressOverlay.setup()
        self.progressOverlay.draw(
            container: self.view,
            coordinates: CGPoint(x: 0.0, y: AKTopOverlayView.LocalConstants.AKViewHeight + 1.0),
            size: CGSize(width: self.view.bounds.width, height: 0.0)
        )
        
        self.topOverlay.controller = self
        self.topOverlay.setup()
        self.topOverlay.draw(
            container: self.view,
            coordinates: CGPoint.zero,
            size: CGSize(width: self.view.bounds.width, height: AKTopOverlayView.LocalConstants.AKViewHeight)
        )
    }
    
    func hideLegend() {
        self.legendOverlay.getView().isHidden = true
    }
    
    func showLegend() {
        self.legendOverlay.getView().isHidden = false
    }
    
    func startRefreshTimer() {
        self.rainmapObserver()
        self.refreshTimer = Timer.scheduledTimer(
            timeInterval: 30.0,
            target: self,
            selector: #selector(AKHeatMapViewController.rainmapObserver),
            userInfo: nil,
            repeats: true
        )
    }
    
    func stopRefreshTimer() {
        if let timer = self.refreshTimer {
            if timer.isValid {
                timer.invalidate()
            }
        }
    }
    
    func stateRefreshTimer() -> Bool {
        if let timer = self.refreshTimer {
            return timer.isValid
        }
        
        return false
    }
}
