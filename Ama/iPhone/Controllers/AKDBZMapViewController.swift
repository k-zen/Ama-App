import CoreLocation
import Foundation
import MapKit
import SVPulsingAnnotationView
import UIKit

class AKDBZMapViewController: AKCustomViewController, MKMapViewDelegate {
    // MARK: Properties
    // Flags
    let addRadarOverlay = false
    let addUserPin = true
    // Overlay Controllers
    let bottomOverlay = AKBottomOverlayView()
    let layersOverlay = AKLayersOverlayView()
    let legendOverlay = AKLegendOverlayView()
    let progressOverlay = AKProgressOverlayView()
    let topOverlay = AKTopOverlayView()
    // Custom Annotations
    var userAnnotation: MKPointAnnotation?
    // Custom Overlays
    var radarOverlay: AKRadarSpanOverlay?
    // Timers
    var refreshTimer: Timer?
    // Misc
    var geoCoordinate: GeoCoordinate?
    
    // MARK: Closures
    let loadDBZMap: (_ controller: AKDBZMapViewController, _ progress: UIProgressView?, _ caller: UIButton) -> Void = { (controller, progress, caller) -> Void in
        // If the layers are not visible/active, then return here and do nothing.
        if !controller.layersOverlay.layersActive { return }
        
        // Disable button/caller.
        caller.isEnabled = false
        UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKDisabledButtonBg })
        
        // Set progress at 25%.
        progress?.setProgress(0.25, animated: true)
        
        // Clear the map.
        controller.clearMap()
        
        // Center on initial position.
        Func.AKCenterMapOnLocation(
            mapView: controller.mapView,
            location: Func.AKDelegate().currentPosition ?? GlobalConstants.AKRadarOrigin,
            zoomLevel: GlobalConstants.AKDefaultZoomLevel
        )
        
        // Call the Controller from a background thread to avoid locking the main thread.
        let user = Func.AKGetUser().username
        let pass = Func.AKGetUser().password
        
        Func.AKExecute(mode: .asyncBackground, timeDelay: 0.0) { () -> Void in
            AKBackEndConnector.obtainSessionToken(
                controller: controller,
                user: user,
                pass: pass,
                completionTask: { (sessionToken) -> Void in
                    AKWSUtils.makeRESTRequest(
                        controller: controller,
                        endpoint: String(format: "%@/ama/datos/ultimodato", GlobalConstants.AKAmaServerAddress),
                        httpMethod: "GET",
                        headerValues: [
                            "Content-Type"  : "application/json",
                            "Authorization" : String(format: "Bearer %@", sessionToken)
                        ],
                        bodyValue: "",
                        showDebugInfo: false,
                        isJSONResponse: true,
                        completionTask: { (jsonDocument) -> Void in
                            let dBZPoints = NSMutableArray()
                            
                            // Set progress at 50% from the main thread.
                            Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { () -> Void in progress?.setProgress(0.50, animated: true) }
                            
                            if let dictionary = jsonDocument as? JSONObject {
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
                                            
                                            // Set progress at 75% from the main thread.
                                            Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { () -> Void in progress?.setProgress(0.75, animated: true) }
                                        }
                                    }
                                    
                                    // Update map, overlays, etc. from the main thread. Also set progress at 100%.
                                    Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { () -> Void in
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
                                        else {
                                            controller.topOverlay.stormCluster.backgroundColor = UIColor.clear
                                        }
                                        progress?.setProgress(1.0, animated: true)
                                    }
                                }
                            }
                            
                            // Reset all.
                            Func.AKExecute(mode: .asyncMain, timeDelay: 2.0) { () -> Void in
                                progress?.setProgress(0.0, animated: false)
                                caller.isEnabled = true
                                UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                            } },
                        failureTask: { (code, message) -> Void in
                            // Reset all.
                            Func.AKExecute(mode: .asyncMain, timeDelay: 2.0) { () -> Void in
                                progress?.setProgress(0.0, animated: false)
                                caller.isEnabled = true
                                UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                            } }
                    ) },
                failureTask: { (code, message) -> Void in
                    // Reset all.
                    Func.AKExecute(mode: .asyncMain, timeDelay: 2.0) { () -> Void in
                        progress?.setProgress(0.0, animated: false)
                        caller.isEnabled = true
                        UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                    } }
            )
        }
    }
    let updateLabels: (AKDBZMapViewController, Any?) -> Void = { (controller, dmhData) -> Void in
        // ###### UPDATE LABELS FOR *TopOverlay*.
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
                with: controller.bottomOverlay.temperature,
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
                with: controller.bottomOverlay.temperature,
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
        let identifier = "UserAnnotation"
        
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            return annotationView
        }
        else {
            let customView = SVPulsingAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            customView.annotationColor = GlobalConstants.AKBlue
            customView.isHidden = true
            
            return customView
        }
    }
    
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
    
    // MARK: Observers
    @objc func locationObserver() {
        NSLog("=> INFO: UPDATED LOCATION.")
        
        Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { () -> Void in
            let coordinate = Func.AKDelegate().currentPosition ?? kCLLocationCoordinate2DInvalid
            
            if self.addUserPin {
                if self.userAnnotation != nil {
                    self.mapView.deselectAnnotation(self.userAnnotation!, animated: true)
                    self.mapView.removeAnnotation(self.userAnnotation!)
                }
                
                self.userAnnotation = MKPointAnnotation()
                self.userAnnotation?.coordinate = coordinate
                self.mapView.addAnnotation(self.userAnnotation!)
            }
        }
    }
    
    @objc func dBZMapObserver() {
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
                // Set up observer for location updates.
                NotificationCenter.default.addObserver(
                    controller,
                    selector: #selector(AKDBZMapViewController.locationObserver),
                    name: NSNotification.Name(GlobalConstants.AKLocationUpdateNotificationName),
                    object: nil
                )
                
                // Configure map.
                controller.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                controller.mapView.userTrackingMode = MKUserTrackingMode.none
                
                // Add radar overlay.
                if controller.addRadarOverlay && controller.radarOverlay == nil {
                    controller.radarOverlay = AKRadarSpanOverlay(center: GlobalConstants.AKRadarOrigin, radius: CLLocationDistance(250000))
                    controller.radarOverlay?.title = "Cobertura Radar"
                    controller.mapView.add(controller.radarOverlay!, level: MKOverlayLevel.aboveRoads)
                }
                
                // Load dBZ map.
                controller.startRefreshTimer()
                
                // Add overlays.
                controller.addDefaultViewOverlays()
                
                // Center on initial position.
                Func.AKCenterMapOnLocation(
                    mapView: controller.mapView,
                    location: Func.AKDelegate().currentPosition ?? GlobalConstants.AKRadarOrigin,
                    zoomLevel: GlobalConstants.AKDefaultZoomLevel
                )
                
                // Call DMH and update data.
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
    
    func toggleMapZoom(enable: Bool) { self.mapView.isZoomEnabled = enable }
    
    func toggleUserAnnotation(enable: Bool) {
        if let annotation = self.userAnnotation {
            if enable {
                self.mapView.view(for: annotation)?.isHidden = false
            }
            else {
                self.mapView.view(for: annotation)?.isHidden = true
            }
        }
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
