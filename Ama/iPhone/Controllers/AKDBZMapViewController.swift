import CoreLocation
import Foundation
import MapKit
import UIKit

class AKDBZMapViewController: AKCustomViewController, MKMapViewDelegate {
    // MARK: Properties
    // Flags
    let addRadarOverlay = true
    // Overlay Controllers
    let bottomOverlay = AKBottomOverlayView()
    let layersOverlay = AKLayersOverlayView()
    let legendOverlay = AKLegendOverlayView()
    let progressOverlay = AKProgressOverlayView()
    let topOverlay = AKTopOverlayView()
    // Custom Overlays
    var radarOverlay: AKRadarSpanOverlay?
    // Timers
    var refreshTimer: Timer?
    // Misc
    var geoCoordinate: GeoCoordinate?
    
    // MARK: Closures
    let loadDBZMap: (_ controller: AKDBZMapViewController, _ progress: UIProgressView?, _ caller: UIButton) -> Void = { (controller, progress, caller) -> Void in
        Func.AKPrintTimeElapsedWhenRunningCode(title: "Load_DBZMap", operation: { (Void) -> Void in
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
            
            let dBZPoints = NSMutableArray()
            let requestBody = ""
            let url = String(format: "%@/ama/ultimodato", GlobalConstants.AKAmaServerAddress)
            let completionTask: (Any) -> Void = { (json) -> Void in
                Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
                    progress?.setProgress(0.50, animated: true)
                }
                
                if let dictionary = json as? JSONObject {
                    if let array = dictionary["arrayDatos"] as? JSONObjectArray, let date = dictionary["fecha"] as? String, let notify = dictionary["notificar"] as? Bool {
                        for element in array {
                            if let e = element as? JSONObject {
                                let intensity = e["dBZ"] as? DBZIntensity ?? GlobalConstants.AKInvalidIntensity
                                let coordinates = e["coordenadas"] as? JSONObjectStringArray ?? []
                                for coordinate in coordinates {
                                    let lat = CLLocationDegrees(coordinate.components(separatedBy: ":")[0])!
                                    let lon = CLLocationDegrees(coordinate.components(separatedBy: ":")[1])!
                                    let location = GeoCoordinate(latitude: lat, longitude: lon)
                                    
                                    dBZPoints.add(AKDBZPoint(center: location, intensity: intensity))
                                }
                                
                                Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
                                    progress?.setProgress(0.75, animated: true)
                                }
                            }
                        }
                        
                        Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
                            controller.mapView.add(AKDBZOverlay(dBZPoints: dBZPoints), level: MKOverlayLevel.aboveRoads)
                            controller.topOverlay.lastUpdate.text = String(
                                format: "Última actualización del radar: %@",
                                Func.AKGetFormattedDate(date: Func.AKGetDateFromString(dateAsString: date))
                            )
                            controller.topOverlay.stormCluster.text = notify ?
                                "Detectamos nubes de lluvia sobre Asunción y alrededores." : "No hay nubes de lluvia sobre Asunción y alrededores."
                            if notify {
                                controller.topOverlay.stormCluster.backgroundColor = Func.AKHexColor(0xCC241D)
                            }
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
    let updateLabels: (AKDBZMapViewController, Any?) -> Void = { (controller, dmhData) -> Void in
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
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: AKDBZOverlay.self) {
            let ol = overlay as! AKDBZOverlay
            return AKDBZOverlayRenderer(overlay: overlay, dBZPoints: ol.dBZPoints as! [AKDBZPoint])
        }
        else if overlay.isKind(of: AKRadarSpanOverlay.self) {
            let ol = overlay as! AKRadarSpanOverlay
            let customView = MKCircleRenderer(circle: MKCircle(center: ol.coordinate, radius: ol.radius))
            customView.fillColor = .black
            customView.alpha = 0.350
            customView.strokeColor = .black
            customView.lineWidth = 1.0
            
            return customView
        }
        else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationCanShowCallout annotation: MKAnnotation) -> Bool {
        return false
    }
    
    // MARK: Observers
    func locationObserver() {
        Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
            if Func.AKDelegate().applicationActive {
                self.callDMHWebService()
            }
        }
    }
    
    func dBZMapObserver() {
        self.loadDBZMap(self, self.progressOverlay.progress, self.layersOverlay.layers)
    }
    
    // MARK: Miscellaneous
    func customSetup() {
        self.shouldCheckLoggedUser = true
        self.inhibitLocationServiceMessage = false
        self.inhibitNotificationMessage = false
        self.inhibitTapGesture = true
        self.loadData = { (controller) -> Void in
            if let controller = controller as? AKDBZMapViewController {
                // Custom notifications.
                NotificationCenter.default.addObserver(
                    controller,
                    selector: #selector(AKDBZMapViewController.locationObserver),
                    name: NSNotification.Name(GlobalConstants.AKLocationUpdateNotificationName),
                    object: nil
                )
                
                // Configure map.
                controller.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                controller.mapView.userTrackingMode = MKUserTrackingMode.none
                
                // Add Radar overlay.
                if controller.addRadarOverlay && controller.radarOverlay == nil {
                    controller.radarOverlay = AKRadarSpanOverlay(center: GlobalConstants.AKRadarOrigin, radius: CLLocationDistance(250000))
                    controller.radarOverlay?.title = "Cobertura Radar"
                    controller.mapView.add(controller.radarOverlay!, level: MKOverlayLevel.aboveRoads)
                }
                
                // Add DBZMap
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
                if overlay.isKind(of: AKRadarSpanOverlay.self) {
                    return false
                }
                else {
                    return true
                }
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
                if overlay.isKind(of: AKDBZOverlay.self) {
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
                y: (self.mapView.bounds.height / 2.0) - (AKLegendOverlayView.LocalConstants.AKViewHeight / 2.0) - 11.0
            ),
            size: CGSize.zero
        )
        
        self.progressOverlay.controller = self
        self.progressOverlay.setup()
        self.progressOverlay.draw(
            container: self.mapView,
            coordinates: CGPoint(x: 0.0, y: AKTopOverlayView.LocalConstants.AKViewHeight),
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
        self.dBZMapObserver()
        self.refreshTimer = Timer.scheduledTimer(
            timeInterval: 30.0,
            target: self,
            selector: #selector(AKDBZMapViewController.dBZMapObserver),
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
