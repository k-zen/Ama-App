import AudioToolbox
import CoreLocation
import Foundation
import MapKit
import TSMessages
import UIKit

class AKHeatMapViewController: AKCustomViewController, MKMapViewDelegate
{
    // MARK: Properties
    private let addRadarOverlay = true
    private let addRadarPin = false
    private let addUserOverlay = false
    private let addUserPin = true
    private let addDIMOverlay = true
    private let hmInfoOverlayViewContainer = AKHeatMapInfoOverlayView()
    private let hmActionsOverlayViewContainer = AKHeatMapActionsOverlayView()
    private let hmAlertsOverlayViewContainer = AKHeatMapAlertsOverlayView()
    private let hmLayersOverlayViewContainer = AKHeatMapLayersOverlayView()
    private let hmLegendOverlayViewContainer = AKHeatMapLegendOverlayView()
    private var radarAnnotation: AKRadarAnnotation?
    private var userAnnotation: AKUserAnnotation?
    private var userAnnotationView: AKUserAnnotationView?
    private var radarOverlay: AKRadarSpanOverlay?
    private var userOverlay: AKUserAreaOverlay?
    private var dimOverlay: AKDIMOverlay?
    private var hmInfoOverlayViewSubView: UIView!
    private var hmActionsOverlayViewSubView: UIView!
    private var hmAlertsOverlayViewSubView: UIView!
    private var hmLayersOverlayViewSubView: UIView!
    private var hmLegendOverlayViewSubView: UIView!
    private var totalRainfallIntensity: Int = 0
    private var refreshTimer: Timer?
    
    // MARK: Closures
    private let loadRainMap: (AKHeatMapViewController, UIProgressView?, UIButton) -> Void = { (controller, progress, caller) -> Void in
        GlobalFunctions.instance(false).AKPrintTimeElapsedWhenRunningCode(title: "Load_HeatMap", operation: { Void -> Void in
            if !controller.hmLayersOverlayViewContainer.layersState {
                return
            }
            
            // AudioServicesPlaySystemSound(1057)
            
            caller.isEnabled = false
            UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKDisabledButtonBg })
            progress?.setProgress(0.25, animated: false)
            
            controller.clearMap()
            controller.addDefaultMapOverlays()
            controller.totalRainfallIntensity = 0
            
            GlobalFunctions.instance(false).AKCenterMapOnLocation(mapView: controller.mapView, location: GlobalConstants.AKRadarOrigin, zoomLevel: ZoomLevel.L03)
            
            let rainfallPoints = NSMutableArray()
            var counter: Int = 0
            let requestBody = ""
            let url = String(format: "%@/app/ultimodato", "http://devel.apkc.net:9001")
            let completionTask: (Any) -> Void = { (json) -> Void in
                GlobalFunctions.instance(false).AKExecuteInMainThread {
                    progress?.setProgress(0.50, animated: true)
                }
                
                // Always check that its a valid JSON document.
                if let dictionary = json as? [String : Any] {
                    if let array = dictionary["arrayDatos"] as? [Any] {
                        for element in array {
                            if let e = element as? [String : Any] {
                                let intensity = e["intensidad"] as? Int ?? GlobalConstants.AKInvalidIntensity
                                let coordinates = e["coordenadas"] as? [String] ?? []
                                for coordinate in coordinates {
                                    let lat = CLLocationDegrees(Double(coordinate.components(separatedBy: ":")[0])!)
                                    let lon = CLLocationDegrees(Double(coordinate.components(separatedBy: ":")[1])!)
                                    let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                    
                                    controller.totalRainfallIntensity += intensity
                                    counter += 1
                                    
                                    rainfallPoints.add(AKRainfallPoint(center: location, intensity: intensity))
                                }
                                
                                GlobalFunctions.instance(false).AKExecuteInMainThread {
                                    progress?.setProgress(0.75, animated: true)
                                }
                            }
                        }
                        
                        GlobalFunctions.instance(false).AKExecuteInMainThread {
                            controller.mapView.add(AKRainOverlay(rainfallPoints: rainfallPoints), level: MKOverlayLevel.aboveRoads)
                            controller.hmInfoOverlayViewContainer.avgRIValue.text = String(format: "%.2fmm/h", (Double(controller.totalRainfallIntensity) / Double(counter)))
                            controller.hmInfoOverlayViewContainer.reflectivityPointsValue.text = String(format: "%d", counter)
                            
                            progress?.setProgress(1.0, animated: true)
                        }
                    }
                }
                
                GlobalFunctions.instance(false).AKExecuteInMainThread {
                    controller.locationUpdated()
                }
                
                GlobalFunctions.instance(false).AKDelay(2.0, task: { Void -> Void in
                    progress?.setProgress(0.0, animated: false)
                    caller.isEnabled = true
                    UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                })
            }
            let failureTask: (Int, String) -> Void = { (code, message) -> Void in
                switch code {
                case ErrorCodes.ConnectionToBackEndError.rawValue:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: message
                    )
                    break
                case ErrorCodes.InvalidMIMEType.rawValue:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: "El servicio devolvió una respuesta inválida. Reportando..."
                    )
                    break
                case ErrorCodes.JSONProcessingError.rawValue:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: "Error procesando respuesta. Reportando..."
                    )
                    break
                default:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: String(format: "%d: Error genérico.", code)
                    )
                    break
                }
                
                GlobalFunctions.instance(false).AKDelay(2.0, task: { Void -> Void in
                    progress?.setProgress(0.0, animated: false)
                    caller.isEnabled = true
                    UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                })
            }
            
            GlobalFunctions.instance(false).AKDelay(0.0, isMain: false, task: { Void -> Void in
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
    private let updateWeatherStatus: (AKHeatMapViewController) -> Void = { (controller) -> Void in
        if GlobalFunctions.instance(false).AKDelegate().applicationActive {
            UIView.transition(
                with: controller.hmAlertsOverlayViewContainer.alertValue,
                duration: 1.00,
                options: [.transitionCrossDissolve],
                animations: {
                    controller.hmAlertsOverlayViewContainer.alertValue.text = "Lluvioso" },
                completion: nil
            )
        }
        else {
            UIView.transition(
                with: controller.hmAlertsOverlayViewContainer.alertValue,
                duration: 1.00,
                options: [.transitionCrossDissolve],
                animations: {
                    controller.hmAlertsOverlayViewContainer.alertValue.text = "Deshabilitado" },
                completion: nil
            )
        }
        
        if GlobalConstants.AKDebug {
            NSLog("=> INFO: NUMBER OF OVERLAYS => %d", controller.mapView.overlays.count)
        }
        
        GlobalFunctions.instance(false).AKDelay(2.0, task: {
            CLGeocoder().reverseGeocodeLocation(
                CLLocation(
                    latitude: GlobalFunctions.instance(false).AKDelegate().currentPosition.latitude,
                    longitude: GlobalFunctions.instance(false).AKDelegate().currentPosition.longitude
                ),
                completionHandler: { (placemarks, error) in
                    if error == nil {
                        if let p = placemarks {
                            if p.count > 0 {
                                UIView.transition(
                                    with: controller.hmAlertsOverlayViewContainer.location,
                                    duration: 1.00,
                                    options: [UIViewAnimationOptions.transitionFlipFromTop],
                                    animations: {
                                        controller.hmAlertsOverlayViewContainer.location.text = String(format: "➤  %@, %@", p[0].locality ?? "---", p[0].country ?? "---") },
                                    completion: nil
                                )
                            }
                        }
                    }}
            )
        })
    }
    
    // MARK: Outlets
    @IBOutlet weak var legendView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: AKCustomViewController Overriding
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.customSetup()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        self.addDefaultViewOverlays()
        GlobalFunctions.instance(false).AKCenterMapOnLocation(mapView: self.mapView, location: GlobalConstants.AKRadarOrigin, zoomLevel: ZoomLevel.L03)
        self.updateWeatherStatus(self)
    }
    
    // MARK: MKMapViewDelegate Implementation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation.isKind(of: AKRadarAnnotation.self) {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.title!!) {
                return annotationView
            }
            else {
                let customView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotation.title!!)
                customView.canShowCallout = true
                customView.layer.backgroundColor = UIColor.clear.cgColor
                customView.layer.cornerRadius = 6.0
                customView.layer.borderWidth = 0.0
                customView.layer.masksToBounds = true
                customView.image = GlobalFunctions.instance(false).AKCircleImageWithRadius(
                    8,
                    strokeColor: UIColor.green,
                    strokeAlpha: 1.0,
                    fillColor: GlobalConstants.AKRadarAnnotationBg,
                    fillAlpha: 1.0,
                    lineWidth: CGFloat(1.4)
                )
                customView.clipsToBounds = false
                
                return customView
            }
        }
        else if annotation.isKind(of: AKUserAnnotation.self) {
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
                    customView.image = GlobalFunctions.instance(false).AKCircleImageWithRadius(
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
        else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        if overlay.isKind(of: AKRadarSpanOverlay.self) {
            let ol = overlay as! AKRadarSpanOverlay
            let customView = MKCircleRenderer(circle: MKCircle(center: ol.coordinate, radius: ol.radius))
            customView.fillColor = UIColor.clear
            customView.alpha = 1.0
            customView.strokeColor = UIColor.green
            customView.lineWidth = 0.175
            
            return customView
        }
        else if overlay.isKind(of: AKUserAreaOverlay.self) {
            let ol = overlay as! AKUserAreaOverlay
            let customView = MKCircleRenderer(circle: MKCircle(center: ol.coordinate, radius: ol.radius))
            customView.fillColor = GlobalConstants.AKUserOverlayBg
            customView.alpha = 0.50
            customView.strokeColor = GlobalConstants.AKUserOverlayBg
            customView.lineWidth = 1.5
            
            return customView
        }
        else if overlay.isKind(of: AKRainOverlay.self) {
            let ol = overlay as! AKRainOverlay
            return AKRainOverlayRenderer(overlay: overlay, rainfallPoints: ol.rainfallPoints as! [AKRainfallPoint])
        }
        else if overlay.isKind(of: AKDIMOverlay.self) {
            return AKDIMOverlayRenderer(overlay: overlay, mapView: self.mapView)
        }
        else if overlay.isKind(of: AKRadarSpanLinesOverlay.self) {
            let ol = overlay as! AKRadarSpanLinesOverlay
            let customView = MKPolylineRenderer(overlay: ol)
            customView.alpha = 1.0
            customView.strokeColor = UIColor.green
            customView.lineWidth = 0.175
            
            return customView
        }
        else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationCanShowCallout annotation: MKAnnotation) -> Bool
    {
        if annotation.isKind(of: AKUserAnnotation.self) {
            return true
        }
        else if annotation.isKind(of: AKRadarAnnotation.self) {
            return true
        }
        else {
            return false
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        if let annotation = view.annotation as? AKUserAnnotation {
            if let v = (Bundle.main.loadNibNamed("AKUserAnnotationView", owner: self, options: nil))?[0] as? AKUserAnnotationView {
                var newFrame = v.frame
                newFrame.origin = CGPoint(x: -newFrame.size.width/2 + 10, y: -newFrame.size.height - 4)
                v.frame = newFrame
                
                v.titleLabel.text = annotation.titleLabel
                v.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
                v.layer.borderWidth = CGFloat(GlobalConstants.AKDefaultBorderThickness)
                v.layer.borderColor = GlobalConstants.AKDefaultViewBorderBg.cgColor
                
                self.userAnnotationView = v
                
                view.addSubview(self.userAnnotationView!)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView)
    {
        if (view.annotation?.isKind(of: AKUserAnnotation.self))! {
            self.userAnnotationView?.removeFromSuperview()
        }
    }
    
    // MARK: Observers
    func locationUpdated()
    {
        GlobalFunctions.instance(false).AKExecuteInMainThread {
            if GlobalFunctions.instance(false).AKDelegate().applicationActive {
                let coordinate = GlobalFunctions.instance(false).AKDelegate().currentPosition
                
                if self.addUserPin {
                    if self.userAnnotation != nil {
                        self.mapView.deselectAnnotation(self.userAnnotation!, animated: true)
                        self.mapView.removeAnnotation(self.userAnnotation!)
                    }
                    
                    self.userAnnotation = AKUserAnnotation(titleLabel: "Mi ubicación ahora...")
                    self.userAnnotation?.coordinate = coordinate
                    self.mapView.addAnnotation(self.userAnnotation!)
                    self.mapView.selectAnnotation(self.userAnnotation!, animated: true)
                }
                
                if self.addUserOverlay {
                    // Remove and add overlay.
                    if let overlay = self.userOverlay {
                        self.mapView.remove(overlay)
                    }
                    self.userOverlay = AKUserAreaOverlay(center: coordinate, radius: 5000)
                    self.userOverlay?.title = "Cobertura Usuario"
                    self.mapView.add(self.userOverlay!, level: MKOverlayLevel.aboveRoads)
                }
                
                self.updateWeatherStatus(self)
            }
        }
    }
    
    // MARK: Miscellaneous
    func customSetup()
    {
        super.shouldCheckLoggedUser = false
        super.inhibitLocationServiceMessage = false
        super.setup()
        
        // Delegates
        self.mapView.delegate = self
        
        // Custom notifications.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AKHeatMapViewController.locationUpdated),
            name: NSNotification.Name(GlobalConstants.AKLocationUpdateNotificationName),
            object: nil
        )
        
        // Configure map.
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.mapView.userTrackingMode = MKUserTrackingMode.none
        
        self.addDefaultMapOverlays()
        
        if addRadarPin {
            self.radarAnnotation = AKRadarAnnotation()
            self.radarAnnotation?.coordinate = GlobalConstants.AKRadarOrigin
            self.radarAnnotation?.title = "Radar"
            self.mapView.addAnnotation(self.radarAnnotation!)
        }
        
        // Add RainMap
        self.startRefreshTimer()
    }
    
    func clearMap()
    {
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
    
    func hideLayers()
    {
        if self.mapView.overlays.count > 0 {
            let overlaysToRemove = self.mapView.overlays.filter({ (overlay) -> Bool in
                if overlay.isKind(of: AKRainOverlay.self) {
                    return true
                }
                else if overlay.isKind(of: AKDIMOverlay.self) {
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
    
    func addDefaultMapOverlays()
    {
        if addDIMOverlay {
            self.dimOverlay = AKDIMOverlay(mapView: self.mapView)
            self.mapView.add(self.dimOverlay!, level: MKOverlayLevel.aboveRoads)
        }
        if addRadarOverlay {
            for k in 1...10 {
                self.radarOverlay = AKRadarSpanOverlay(center: GlobalConstants.AKRadarOrigin, radius: CLLocationDistance(5000 * k))
                self.radarOverlay?.title = "Cobertura Radar"
                self.mapView.add(self.radarOverlay!, level: MKOverlayLevel.aboveRoads)
            }
            
            for k in 1...12 {
                self.mapView.add(
                    AKRadarSpanLinesOverlay(
                        coordinates: [
                            GlobalConstants.AKRadarOrigin,
                            GlobalFunctions.instance(false).AKLocationWithBearing(
                                bearing: Double(k * 30) * (M_PI / 180),
                                distanceMeters: 50000,
                                origin: GlobalConstants.AKRadarOrigin
                            )
                        ],
                        count: 2
                    )
                )
            }
        }
    }
    
    func addDefaultViewOverlays()
    {
        // Add map overlay for heatmap information.
        // self.hmInfoOverlayViewSubView = self.hmInfoOverlayViewContainer.customView
        // self.hmInfoOverlayViewContainer.controller = self
        // self.hmInfoOverlayViewSubView.frame = CGRect(x: 0, y: self.mapView.bounds.height - 60, width: self.mapView.bounds.width, height: 60)
        // self.hmInfoOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        // self.hmInfoOverlayViewSubView.clipsToBounds = true
        // self.hmInfoOverlayViewSubView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // self.mapView.addSubview(self.hmInfoOverlayViewSubView)
        
        // Add map overlay for heatmap alerts.
        self.hmAlertsOverlayViewSubView = self.hmAlertsOverlayViewContainer.customView
        self.hmAlertsOverlayViewContainer.controller = self
        self.hmAlertsOverlayViewSubView.frame = CGRect(
            x: 0,
            y: 0,
            width: self.view.bounds.width,
            height: self.hmAlertsOverlayViewSubView.bounds.height
        )
        self.hmAlertsOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        self.hmAlertsOverlayViewSubView.clipsToBounds = true
        self.view.addSubview(self.hmAlertsOverlayViewSubView)
        
        // Add map overlay for heatmap actions.
        self.hmActionsOverlayViewSubView = self.hmActionsOverlayViewContainer.customView
        self.hmActionsOverlayViewContainer.controller = self
        self.hmActionsOverlayViewSubView.frame = CGRect(
            x: 0,
            y: self.hmAlertsOverlayViewSubView.bounds.height + 1,
            width: self.view.bounds.width,
            height: self.hmActionsOverlayViewSubView.bounds.height
        )
        self.hmActionsOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        self.hmActionsOverlayViewSubView.clipsToBounds = true
        self.view.addSubview(self.hmActionsOverlayViewSubView)
        
        // Add map overlay for heatmap layers.
        self.hmLayersOverlayViewSubView = self.hmLayersOverlayViewContainer.customView
        self.hmLayersOverlayViewContainer.controller = self
        self.hmLayersOverlayViewSubView.frame = CGRect(
            x: self.mapView.bounds.width - self.hmLayersOverlayViewSubView.bounds.width,
            y: (self.mapView.bounds.height / 2.0) - (self.hmLayersOverlayViewSubView.bounds.height / 2.0),
            width: self.hmLayersOverlayViewSubView.bounds.width,
            height: self.hmLayersOverlayViewSubView.bounds.height
        )
        self.hmLayersOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        self.hmLayersOverlayViewSubView.clipsToBounds = true
        self.mapView.addSubview(self.hmLayersOverlayViewSubView)
        
        // Add map overlay for heatmap legend.
        self.hmLegendOverlayViewSubView = self.hmLegendOverlayViewContainer.customView
        self.hmLegendOverlayViewContainer.controller = self
        self.hmLegendOverlayViewSubView.frame = CGRect(
            x: 0,
            y: (self.mapView.bounds.height / 2.0) - (self.hmLegendOverlayViewSubView.bounds.height / 2.0),
            width: self.hmLegendOverlayViewSubView.bounds.width,
            height: self.hmLegendOverlayViewSubView.bounds.height
        )
        self.hmLegendOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        self.hmLegendOverlayViewSubView.clipsToBounds = true
        self.mapView.addSubview(self.hmLegendOverlayViewSubView)
        
        // Custom L&F
        // self.hmInfoOverlayViewSubView.backgroundColor = GlobalConstants.AKOverlaysBg
        self.hmAlertsOverlayViewSubView.backgroundColor = GlobalConstants.AKOverlaysBg
        self.hmLegendOverlayViewSubView.backgroundColor = GlobalConstants.AKOverlaysBg
        
        GlobalFunctions.instance(false).AKAddBorderDeco(
            self.hmAlertsOverlayViewSubView,
            color: GlobalConstants.AKDefaultViewBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.bottom
        )
    }
    
    func loadRainMapFunction() { self.loadRainMap(self, self.hmActionsOverlayViewContainer.progress, self.hmLayersOverlayViewContainer.layers) }
    
    func hideLegend() { self.hmLegendOverlayViewSubView.isHidden = true }
    
    func showLegend() { self.hmLegendOverlayViewSubView.isHidden = false }
    
    func startRefreshTimer()
    {
        self.loadRainMapFunction()
        self.refreshTimer = Timer.scheduledTimer(
            timeInterval: 30.0,
            target: self,
            selector: #selector(AKHeatMapViewController.loadRainMapFunction),
            userInfo: nil,
            repeats: true
        )
    }
    
    func stopRefreshTimer()
    {
        if let timer = self.refreshTimer {
            if timer.isValid {
                timer.invalidate()
            }
        }
    }
    
    func stateRefreshTimer() -> Bool
    {
        if let timer = self.refreshTimer {
            return timer.isValid
        }
        
        return false
    }
}
