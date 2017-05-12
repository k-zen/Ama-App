import CoreLocation
import Foundation
import MapKit
import SVPulsingAnnotationView
import UIKit

class AKHeatMapViewController: AKCustomViewController, MKMapViewDelegate {
    // MARK: Properties
    // Flags
    let addUserPin = true
    // Overlay Controllers
    let bottomOverlay = AKBottomOverlayView()
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
            
            Func.AKExecute(mode: .asyncMain, timeDelay: 2.0) { (Void) -> Void in
                Func.AKCenterMapOnLocation(
                    mapView: controller.mapView,
                    location: Func.AKDelegate().currentPosition ?? GlobalConstants.AKRadarOrigin,
                    zoomLevel: GlobalConstants.AKDefaultZoomLevel
                )
            }
            
            let rainfallPoints = NSMutableArray()
            let requestBody = ""
            let url = String(format: "%@/ama/ultimodato", GlobalConstants.AKAmaServerAddress)
            let completionTask: (Any) -> Void = { (json) -> Void in
                Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
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
                                
                                Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
                                    progress?.setProgress(0.75, animated: true)
                                }
                            }
                        }
                        
                        Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
                            controller.mapView.add(AKRainOverlay(rainfallPoints: rainfallPoints), level: MKOverlayLevel.aboveRoads)
                            progress?.setProgress(1.0, animated: true)
                        }
                    }
                }
                
                Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
                    controller.locationObserver()
                }
                
                Func.AKExecute(mode: .asyncMain, timeDelay: 2.0) { (Void) -> Void in
                    progress?.setProgress(0.0, animated: false)
                    caller.isEnabled = true
                    UIView.animate(withDuration: 1.0, animations: { (Void) -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                }
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
                
                Func.AKExecute(mode: .asyncMain, timeDelay: 2.0) { (Void) -> Void in
                    progress?.setProgress(0.0, animated: false)
                    caller.isEnabled = true
                    UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                }
            }
            
            Func.AKExecute(mode: .asyncBackground, timeDelay: 0.0) { Void -> Void in
                AKWSUtils.makeRESTRequest(
                    controller: controller,
                    endpoint: url,
                    httpMethod: "GET",
                    headerValues: [ "Content-Type" : "application/json" ],
                    bodyValue: requestBody,
                    completionTask: { (jsonDocument) -> Void in completionTask(jsonDocument) },
                    failureTask: { (code, message) -> Void in failureTask(code, message!) }
                )
            }
        })
    }
    let updateLabels: (AKHeatMapViewController, Any?) -> Void = { (controller, dmhData) -> Void in
        // ###### UPDATE LABELS FOR *TopOverlay*.
        controller.topOverlay.userAvatar.text = String(format: "%@", Func.AKGetUser().username.characters.first?.description ?? "").uppercased()
        
        // Update the *Weather State*.
        if
            let array = dmhData as? JSONObjectArray,
            let dictionary = array[0] as? JSONObject,
            let currentData = dictionary["datos_actuales"] as? JSONObject,
            let weatherState = currentData["tiempo_presente"] as? WeatherState {
            UIView.transition(
                with: controller.topOverlay.alertValue,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: { controller.topOverlay.alertValue.text = weatherState },
                completion: nil
            )
        }
        else {
            UIView.transition(
                with: controller.topOverlay.alertValue,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: { controller.topOverlay.alertValue.text = "---" },
                completion: nil
            )
        }
        
        // Update the user's current location's information. Street, City, etc.
        Func.AKExecute(mode: .asyncMain, timeDelay: 2.0) {
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
        }
        // ###### UPDATE LABELS FOR *TopOverlay*.
        
        // ###### UPDATE LABELS FOR *BottomOverlay*.
        // Update the *Forecast*, *Temperature*, *Humidity* and *Wind*.
        if
            let array = dmhData as? JSONObjectArray,
            let dictionary = array[0] as? JSONObject,
            let forecast = dictionary["pronosticos"] as? JSONObjectArray,
            let today = forecast[0] as? JSONObject,
            let description = today["descripcion"] as? Forecast {
            UIView.transition(
                with: controller.bottomOverlay.temperature,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: {
                    controller.bottomOverlay.forecast.text = String(format: "%@", description) },
                completion: nil
            )
        }
        else {
            UIView.transition(
                with: controller.topOverlay.alertValue,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: {
                    controller.bottomOverlay.forecast.text = "---" },
                completion: nil
            )
        }
        
        if
            let array = dmhData as? JSONObjectArray,
            let dictionary = array[0] as? JSONObject,
            let currentData = dictionary["datos_actuales"] as? JSONObject,
            let temperature = currentData["temp_aire"] as? Temperature,
            let humidity = currentData["humedad_relativa"] as? Humidity,
            let windDirection = currentData["dir_viento"] as? WindDirection,
            let windVelocity = currentData["vel_viento"] as? WindVelocity {
            UIView.transition(
                with: controller.bottomOverlay.temperature,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: {
                    controller.bottomOverlay.temperature.text = String(format: "%.0fº", temperature)
                    controller.bottomOverlay.humidity.text = String(format: "%.0f%%", humidity)
                    controller.bottomOverlay.windDirection.text = String(format: "%@", windDirection)
                    controller.bottomOverlay.windVelocity.text = String(format: "%i km/h", windVelocity) },
                completion: nil
            )
        }
        else {
            UIView.transition(
                with: controller.topOverlay.alertValue,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: {
                    controller.bottomOverlay.temperature.text = "---"
                    controller.bottomOverlay.humidity.text = "---"
                    controller.bottomOverlay.windDirection.text = "---"
                    controller.bottomOverlay.windVelocity.text = "---" },
                completion: nil
            )
        }
        // ###### UPDATE LABELS FOR *BottomOverlay*.
        
        if GlobalConstants.AKDebug {
            NSLog("=> INFO: NUMBER OF OVERLAYS => %d", controller.mapView.overlays.count)
        }
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
                    let customView = SVPulsingAnnotationView(annotation: annotation, reuseIdentifier: custom.titleLabel)
                    customView.annotationColor = GlobalConstants.AKUserAnnotationBg
                    
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
                    let customView = SVPulsingAnnotationView(annotation: annotation, reuseIdentifier: custom.titleLabel)
                    customView.annotationColor = GlobalConstants.AKAlertAnnotationBg
                    
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
                    v.layer.cornerRadius = GlobalConstants.AKViewCornerRadius
                    v.layer.masksToBounds = true
                    
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
        Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
            if Func.AKDelegate().applicationActive {
                let coordinate = Func.AKDelegate().currentPosition ?? kCLLocationCoordinate2DInvalid
                
                if self.addUserPin {
                    if self.userAnnotation != nil {
                        self.mapView.deselectAnnotation(self.userAnnotation!, animated: true)
                        self.mapView.removeAnnotation(self.userAnnotation!)
                    }
                    
                    self.userAnnotation = AKUserAnnotation(titleLabel: "Tu ubicación.")
                    self.userAnnotation?.coordinate = coordinate
                    self.mapView.addAnnotation(self.userAnnotation!)
                }
                
                self.callDMHWebService()
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
                Func.AKExecute(mode: .asyncMain, timeDelay: 2.0) {
                    for alert in Func.AKGetUser().userDefinedAlerts {
                        controller.mapView.addAnnotation(alert.alertAnnotation)
                        // controller.mapView.selectAnnotation(alert.alertAnnotation, animated: true)
                    }
                }
                
                // Add RainMap
                controller.startRefreshTimer()
                
                controller.addDefaultViewOverlays()
                Func.AKCenterMapOnLocation(
                    mapView: controller.mapView,
                    location: Func.AKDelegate().currentPosition ?? GlobalConstants.AKRadarOrigin,
                    zoomLevel: GlobalConstants.AKDefaultZoomLevel
                )
                controller.callDMHWebService()
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
        self.bottomOverlay.controller = self
        self.bottomOverlay.setup()
        self.bottomOverlay.draw(
            container: self.mapView,
            coordinates: CGPoint(
                x: 0.0,
                y: (self.mapView.bounds.height) - (AKBottomOverlayView.LocalConstants.AKViewHeight)
            ),
            size: CGSize(width: self.view.bounds.width, height: 0.0)
        )
        
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
            container: self.mapView,
            coordinates: CGPoint(x: 0.0, y: AKTopOverlayView.LocalConstants.AKViewHeight + 1.0),
            size: CGSize(width: self.view.bounds.width, height: 0.0)
        )
        
        self.topOverlay.controller = self
        self.topOverlay.setup()
        self.topOverlay.draw(
            container: self.mapView,
            coordinates: CGPoint.zero,
            size: CGSize(width: self.view.bounds.width, height: 0.0)
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
    
    func callDMHWebService() {
        Func.AKExecute(mode: .asyncBackground, timeDelay: 0.0) {
            AKWSUtils.makeRESTRequest(
                controller: self,
                endpoint: String(format: "%@", GlobalConstants.AKDMHServerAddress),
                httpMethod: "GET",
                headerValues: [ "Content-Type" : "application/json" ],
                bodyValue: "",
                showDebugInfo: false,
                isJSONResponse: true,
                completionTask: { (json) -> Void in
                    Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) {
                        self.updateLabels(self, json)
                    } },
                failureTask: { (code, message) -> Void in
                    Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) {
                        self.updateLabels(self, nil)
                    } }
            )
        }
    }
}
