import CoreLocation
import Foundation
import MapKit
import TSMessages
import UIKit

class AKRadarAnnotation: MKPointAnnotation {}
class AKUserAnnotation: MKPointAnnotation {}

class AKHeatMapViewController: AKCustomViewController, MKMapViewDelegate
{
    // MARK: Properties
    private let addRadarOverlay = true
    private let addRadarPin = true
    private let addUserOverlay = true
    private let addUserPin = true
    private let addDIMOverlay = true
    private let hmInfoOverlayViewContainer: AKHeatMapInfoOverlayView = AKHeatMapInfoOverlayView()
    private let hmActionsOverlayViewContainer: AKHeatMapActionsOverlayView = AKHeatMapActionsOverlayView()
    private let hmAlertsOverlayViewContainer: AKHeatMapAlertsOverlayView = AKHeatMapAlertsOverlayView()
    private let radarAnnotation: AKRadarAnnotation = AKRadarAnnotation()
    private let userAnnotation: AKUserAnnotation = AKUserAnnotation()
    private var radarOverlay: AKRadarSpanOverlay?
    private var userOverlay: AKUserAreaOverlay?
    private var hmInfoOverlayViewSubView: UIView!
    private var hmActionsOverlayViewSubView: UIView!
    private var hmAlertsOverlayViewSubView: UIView!
    private var totalRainfallIntensity: Int = 0
    
    // MARK: Closures
    internal let loadRainMap: (AKHeatMapViewController, UIActivityIndicatorView?) -> Void = { (controller, spinner) -> Void in
        GlobalFunctions.AKPrintTimeElapsedWhenRunningCode(title: "Load_HeatMap", operation: { Void -> Void in
            spinner?.startAnimating()
            
            let rainfallPoints = NSMutableArray()
            var counter: Int = 0
            
            controller.clearMap()
            controller.totalRainfallIntensity = 0
            GlobalFunctions.AKCenterMapOnLocation(mapView: controller.mapView, location: GlobalConstants.AKRadarOrigin, zoomLevel: ZoomLevel.L03)
            
            let requestBody = ""
            let url = String(format: "%@/app/ultimodato", "http://devel.apkc.net:9001")
            let completionTask: (Any) -> Void = { (json) -> Void in
                GlobalFunctions.AKDelay(0.0, task: { Void -> Void in
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
                                }
                            }
                            
                            controller.mapView.add(AKRainOverlay(rainfallPoints: rainfallPoints), level: MKOverlayLevel.aboveRoads)
                            controller.hmInfoOverlayViewContainer.avgRIValue.text = String(format: "%.2fmm/h", (Double(controller.totalRainfallIntensity) / Double(counter)))
                            controller.hmInfoOverlayViewContainer.reflectivityPointsValue.text = String(format: "%d", counter)
                        }
                    }
                    
                    spinner?.stopAnimating()
                })
            }
            let failureTask: (Int, String) -> Void = { (code, message) -> Void in
                switch code {
                case ErrorCodes.ConnectionToBackEndError.rawValue:
                    GlobalFunctions.AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: message
                    )
                    break
                case ErrorCodes.InvalidMIMEType.rawValue:
                    GlobalFunctions.AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: "El servicio devolvió una respuesta inválida. Reportando..."
                    )
                    break
                case ErrorCodes.JSONProcessingError.rawValue:
                    GlobalFunctions.AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: "Error procesando respuesta. Reportando..."
                    )
                    break
                default:
                    GlobalFunctions.AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: String(format: "%d: Error genérico.", code)
                    )
                    break
                }
                
                spinner?.stopAnimating()
            }
            
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
    }
    private let updateWeatherStatus: (AKHeatMapViewController) -> Void = { (controller) -> Void in
        if GlobalFunctions.AKDelegate().applicationActive {
            controller.hmAlertsOverlayViewContainer.alertValue.text = String(format: "En tu zona: Lluvioso")
        }
        else {
            controller.hmAlertsOverlayViewContainer.alertValue.text = "Deshabilitado"
        }
        
        if GlobalConstants.AKDebug {
            NSLog("=> INFO: NUMBER OF OVERLAYS => %d", controller.mapView.overlays.count)
        }
    }
    
    // MARK: Outlets
    @IBOutlet weak var legendView: UIView!
    @IBOutlet weak var img01: UIImageView!
    @IBOutlet weak var img02: UIImageView!
    @IBOutlet weak var img03: UIImageView!
    @IBOutlet weak var img04: UIImageView!
    @IBOutlet weak var img05: UIImageView!
    @IBOutlet weak var img06: UIImageView!
    @IBOutlet weak var img07: UIImageView!
    @IBOutlet weak var img08: UIImageView!
    @IBOutlet weak var img09: UIImageView!
    @IBOutlet weak var img10: UIImageView!
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
        GlobalFunctions.AKCenterMapOnLocation(mapView: self.mapView, location: GlobalConstants.AKRadarOrigin, zoomLevel: ZoomLevel.L03)
        updateWeatherStatus(self)
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
                customView.image = GlobalFunctions.AKCircleImageWithRadius(
                    10,
                    strokeColor: UIColor.black,
                    strokeAlpha: 1.0,
                    fillColor: GlobalConstants.AKRadarAnnotationBg,
                    fillAlpha: 1.0,
                    lineWidth: CGFloat(1.4)
                )
                customView.clipsToBounds = false
                
                return customView
            }
        }
        if annotation.isKind(of: AKUserAnnotation.self) {
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
                customView.image = GlobalFunctions.AKCircleImageWithRadius(
                    10,
                    strokeColor: UIColor.black,
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
            customView.alpha = 0.25
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
    
    func mapView(_ mapView: MKMapView, annotationCanShowCallout annotation: MKAnnotation) -> Bool { return true }
    
    // MARK: Observers
    func locationUpdated()
    {
        GlobalFunctions.AKExecuteInMainThread {
            if GlobalFunctions.AKDelegate().applicationActive {
                let coordinate = GlobalFunctions.AKDelegate().currentPosition
                
                if self.addUserPin {
                    self.userAnnotation.coordinate = coordinate
                    self.userAnnotation.title = "Usuario"
                    self.userAnnotation.subtitle = String(format: "Lat: %f, Lng: %f", coordinate.latitude, coordinate.longitude)
                    self.mapView.addAnnotation(self.userAnnotation)
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
        
        // Create Legend
        let frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        self.img01.image = UIImage.fromColor(color: GlobalFunctions.AKHexColor(HeatMapColor.C01.rawValue), frame: frame)
        self.img02.image = UIImage.fromColor(color: GlobalFunctions.AKHexColor(HeatMapColor.C02.rawValue), frame: frame)
        self.img03.image = UIImage.fromColor(color: GlobalFunctions.AKHexColor(HeatMapColor.C03.rawValue), frame: frame)
        self.img04.image = UIImage.fromColor(color: GlobalFunctions.AKHexColor(HeatMapColor.C04.rawValue), frame: frame)
        self.img05.image = UIImage.fromColor(color: GlobalFunctions.AKHexColor(HeatMapColor.C05.rawValue), frame: frame)
        self.img06.image = UIImage.fromColor(color: GlobalFunctions.AKHexColor(HeatMapColor.C06.rawValue), frame: frame)
        self.img07.image = UIImage.fromColor(color: GlobalFunctions.AKHexColor(HeatMapColor.C07.rawValue), frame: frame)
        self.img08.image = UIImage.fromColor(color: GlobalFunctions.AKHexColor(HeatMapColor.C08.rawValue), frame: frame)
        self.img09.image = UIImage.fromColor(color: GlobalFunctions.AKHexColor(HeatMapColor.C09.rawValue), frame: frame)
        self.img10.image = UIImage.fromColor(color: GlobalFunctions.AKHexColor(HeatMapColor.C10.rawValue), frame: frame)
        
        // Configure map.
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.mapView.userTrackingMode = MKUserTrackingMode.none
        
        // Add map overlay for heatmap information.
        self.hmInfoOverlayViewSubView = self.hmInfoOverlayViewContainer.customView
        self.hmInfoOverlayViewContainer.controller = self
        self.hmInfoOverlayViewSubView.frame = CGRect(x: 0, y: self.mapView.bounds.height - 60, width: self.mapView.bounds.width, height: 60)
        self.hmInfoOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        self.hmInfoOverlayViewSubView.clipsToBounds = true
        self.hmInfoOverlayViewSubView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.mapView.addSubview(self.hmInfoOverlayViewSubView)
        self.mapView.addConstraint(NSLayoutConstraint(
            item: self.hmInfoOverlayViewSubView,
            attribute: NSLayoutAttribute.width,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.mapView,
            attribute: NSLayoutAttribute.width,
            multiplier: 1.0,
            constant: 0.0
        ))
        
        // Add map overlay for heatmap actions.
        self.hmActionsOverlayViewSubView = self.hmActionsOverlayViewContainer.customView
        self.hmActionsOverlayViewContainer.controller = self
        self.hmActionsOverlayViewSubView.frame = CGRect(x: 0, y: 30, width: self.mapView.bounds.width, height: 40)
        self.hmActionsOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        self.hmActionsOverlayViewSubView.clipsToBounds = true
        self.hmActionsOverlayViewSubView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.mapView.addSubview(self.hmActionsOverlayViewSubView)
        self.mapView.addConstraint(NSLayoutConstraint(
            item: self.hmActionsOverlayViewSubView,
            attribute: NSLayoutAttribute.width,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.mapView,
            attribute: NSLayoutAttribute.width,
            multiplier: 1.0,
            constant: 0.0
        ))
        
        // Add map overlay for heatmap alerts.
        self.hmAlertsOverlayViewSubView = self.hmAlertsOverlayViewContainer.customView
        self.hmAlertsOverlayViewContainer.controller = self
        self.hmAlertsOverlayViewSubView.frame = CGRect(x: 0, y: 0, width: self.mapView.bounds.width, height: 30)
        self.hmAlertsOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        self.hmAlertsOverlayViewSubView.clipsToBounds = true
        self.hmAlertsOverlayViewSubView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.mapView.addSubview(self.hmAlertsOverlayViewSubView)
        self.mapView.addConstraint(NSLayoutConstraint(
            item: self.hmAlertsOverlayViewSubView,
            attribute: NSLayoutAttribute.width,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.mapView,
            attribute: NSLayoutAttribute.width,
            multiplier: 1.0,
            constant: 0.0
        ))
        
        if addDIMOverlay {
            self.mapView.add(
                AKDIMOverlay(mapView: self.mapView),
                level: MKOverlayLevel.aboveRoads
            )
        }
        
        // Add radar annotation & overlay.
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
                            GlobalFunctions.AKLocationWithBearing(
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
        if addRadarPin {
            self.radarAnnotation.coordinate = GlobalConstants.AKRadarOrigin
            self.radarAnnotation.title = "Radar"
            self.radarAnnotation.subtitle = String(
                format: "Lat: %f, Lng: %f",
                GlobalConstants.AKRadarOrigin.latitude,
                GlobalConstants.AKRadarOrigin.longitude
            )
            self.mapView.addAnnotation(self.radarAnnotation)
        }
        
        // Custom L&F
        self.hmInfoOverlayViewSubView.backgroundColor = GlobalConstants.AKOverlaysBg
        self.hmAlertsOverlayViewSubView.backgroundColor = GlobalConstants.AKOverlaysBg
        
        GlobalFunctions.AKAddBorderDeco(
            self.hmInfoOverlayViewSubView,
            color: GlobalConstants.AKDefaultViewBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.bottom
        )
        GlobalFunctions.AKAddBorderDeco(
            self.legendView,
            color: GlobalConstants.AKDefaultViewBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.bottom
        )
        
        // Add HeatMap
        self.loadRainMap(self, nil)
    }
    
    func clearMap()
    {
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
}
