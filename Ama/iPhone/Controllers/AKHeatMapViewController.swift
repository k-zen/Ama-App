import CoreLocation
import Foundation
import MapKit
import UIKit

class AKHeatMapViewController: AKCustomViewController, MKMapViewDelegate
{
    // MARK: Properties
    // Flags
    let addRadarOverlay = false
    let addRadarPin = false
    let addUserOverlay = false
    let addUserPin = true
    let addDIMOverlay = false
    // Overlay Controllers
    let layersOverlay = AKLayersOverlayView()
    let legendOverlay = AKLegendOverlayView()
    let progressOverlay = AKProgressOverlayView()
    let topOverlay = AKTopOverlayView()
    // Custom Annotations
    var radarAnnotation: AKRadarAnnotation?
    var userAnnotation: AKUserAnnotation?
    // Custom Annotation Views
    var userAnnotationView: AKUserAnnotationView?
    // Custom Overlays
    var radarOverlay: AKRadarSpanOverlay?
    var userOverlay: AKUserAreaOverlay?
    var dimOverlay: AKDIMOverlay?
    // Timers
    var refreshTimer: Timer?
    // Misc
    var geoCoordinate: GeoCoordinate?
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: AKCustomViewController Overriding
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.customSetup()
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
                customView.image = Func.AKCircleImageWithRadius(
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
        else if annotation.isKind(of: AKAlertAnnotation.self) {
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
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView)
    {
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
    func locationObserver()
    {
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
                
                if self.addUserOverlay {
                    // Remove and add overlay.
                    if let overlay = self.userOverlay {
                        self.mapView.remove(overlay)
                    }
                    self.userOverlay = AKUserAreaOverlay(center: coordinate, radius: 5000.0)
                    self.userOverlay?.title = "Cobertura Usuario"
                    self.mapView.add(self.userOverlay!, level: MKOverlayLevel.aboveRoads)
                }
                
                AKHeatMapClosures.updateWeatherStatus(self)
            }
        }
    }
    
    func rainmapObserver()
    {
        AKHeatMapClosures.loadRainMap(
            self,
            self.progressOverlay.progress,
            self.layersOverlay.layers
        )
    }
    
    // MARK: Miscellaneous
    func customSetup()
    {
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
                
                AKHeatMapUtilityFunctions.addDefaultMapOverlays(controller)
                
                if controller.addRadarPin {
                    controller.radarAnnotation = AKRadarAnnotation()
                    controller.radarAnnotation?.coordinate = GlobalConstants.AKRadarOrigin
                    controller.radarAnnotation?.title = "Radar"
                    controller.mapView.addAnnotation(controller.radarAnnotation!)
                }
                
                // Load all user defined alerts.
                Func.AKDelay(2.0, task: {
                    for alert in Func.AKGetUser().userDefinedAlerts {
                        controller.mapView.addAnnotation(alert.alertAnnotation)
                        controller.mapView.selectAnnotation(alert.alertAnnotation, animated: true)
                    }
                })
                
                // Add RainMap
                AKHeatMapUtilityFunctions.startRefreshTimer(controller)
                
                AKHeatMapUtilityFunctions.addDefaultViewOverlays(controller)
                Func.AKCenterMapOnLocation(
                    mapView: controller.mapView,
                    location: Func.AKDelegate().currentPosition ?? GlobalConstants.AKRadarOrigin,
                    zoomLevel: GlobalConstants.AKDefaultZoomLevel
                )
                AKHeatMapClosures.updateWeatherStatus(controller)
            }
        }
        self.setup()
        
        // Delegates
        self.mapView.delegate = self
    }
}
