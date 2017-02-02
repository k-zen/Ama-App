import AudioToolbox
import CoreLocation
import Foundation
import MapKit
import TSMessages
import UIKit

/// ViewController for the rainmap/heatmap.
///
/// - Author: Andreas P. Koenzen <akc@apkc.net>
/// - Copyright: 2017 APKC.net
/// - Date: Jan 24, 2017
class AKHeatMapViewController: AKCustomViewController, MKMapViewDelegate
{
    // MARK: Properties
    // Flags
    let addRadarOverlay = true
    let addRadarPin = false
    let addUserOverlay = false
    let addUserPin = true
    let addDIMOverlay = true
    // View Overlay Controllers
    let hmActionsOverlayViewContainer = AKHeatMapActionsOverlayView()
    let hmAlertsOverlayViewContainer = AKHeatMapAlertsOverlayView()
    let hmLayersOverlayViewContainer = AKHeatMapLayersOverlayView()
    let hmLegendOverlayViewContainer = AKHeatMapLegendOverlayView()
    // Custom Annotations
    var radarAnnotation: AKRadarAnnotation?
    var userAnnotation: AKUserAnnotation?
    // Custom Annotation Views
    var userAnnotationView: AKUserAnnotationView?
    // Custom Overlays
    var radarOverlay: AKRadarSpanOverlay?
    var userOverlay: AKUserAreaOverlay?
    var dimOverlay: AKDIMOverlay?
    // Custom View Overlays
    var hmInfoOverlayViewSubView: UIView!
    var hmActionsOverlayViewSubView: UIView!
    var hmAlertsOverlayViewSubView: UIView!
    var hmLayersOverlayViewSubView: UIView!
    var hmLegendOverlayViewSubView: UIView!
    // Timers
    var refreshTimer: Timer?
    
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
        AKHeatMapUtilityFunctions.addDefaultViewOverlays(self)
        GlobalFunctions.instance(false).AKCenterMapOnLocation(
            mapView: self.mapView,
            location: GlobalConstants.AKRadarOrigin,
            zoomLevel: ZoomLevel.L03
        )
        AKHeatMapClosures.updateWeatherStatus(self)
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
                    customView.image = GlobalFunctions.instance(false).AKCircleImageWithRadius(
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
                    newFrame.origin = CGPoint(x: -newFrame.size.width/2 + 10, y: -newFrame.size.height - 4)
                    v.frame = newFrame
                    
                    v.titleLabel.text = annotation.titleLabel
                    v.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
                    v.layer.borderWidth = CGFloat(GlobalConstants.AKDefaultBorderThickness)
                    v.layer.borderColor = GlobalConstants.AKDefaultViewBorderBg.cgColor
                    
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
                if let alert = GlobalFunctions.instance(false).AKObtainMasterFile().user.findAlert(id: annotation.id) {
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
                if let alert = GlobalFunctions.instance(false).AKObtainMasterFile().user.findAlert(id: annotation.id) {
                    alert.alertView.removeFromSuperview()
                }
            }
        }
    }
    
    // MARK: Observers
    func locationObserver()
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
                    // self.mapView.selectAnnotation(self.userAnnotation!, animated: true)
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
                
                AKHeatMapClosures.updateWeatherStatus(self)
            }
        }
    }
    
    func rainmapObserver()
    {
        AKHeatMapClosures.loadRainMap(
            self,
            self.hmActionsOverlayViewContainer.progress,
            self.hmLayersOverlayViewContainer.layers
        )
    }
    
    // MARK: Miscellaneous
    func customSetup()
    {
        super.shouldCheckLoggedUser = false
        super.inhibitLocationServiceMessage = false
        super.inhibitTapGesture = true
        super.inhibitLongPressGesture = false
        super.setup()
        
        // Overwrite closures.
        self.additionalOperationsWhenLongPressed = { (gesture) -> Void in
            if let g = gesture as? UILongPressGestureRecognizer {
                if g.state == UIGestureRecognizerState.ended {
                    if GlobalFunctions.instance(false).AKObtainMasterFile().user.countAlerts() >= GlobalConstants.AKMaxUserDefinedAlerts {
                        GlobalFunctions.instance(false).AKPresentTopMessage(
                            self,
                            type: TSMessageNotificationType.error,
                            message: "Has alcanzado el límite de alertas!"
                        )
                        return
                    }
                    
                    let touchPoint = g.location(in: self.mapView)
                    let geoCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
                    self.presentAlerPINInputView(coordinates: geoCoordinate, dismissViewCompletionTask: { (controller, presentedController, coordinates) -> Void in
                        if let controller = controller as? AKHeatMapViewController {
                            if let presentedController = presentedController as? AKAlertPINInputViewController {
                                let id = UUID().uuidString
                                let name = presentedController.nameValue.text ?? "Sin Nombre"
                                let radius = presentedController.radioSlider.value * 10.0
                                let title = name
                                let subtitle = String(format: "Radio de : %.1fkm", radius)
                                
                                let annotation = AKAlertAnnotation(id: id, titleLabel: title, subtitleLabel: subtitle, location: coordinates)
                                
                                let alert = Alert(alertID: id, alertName: name, alertRadius: Double(radius), alertAnnotation: annotation)
                                
                                GlobalFunctions.instance(false).AKObtainMasterFile().user.addAlert(alert: alert)
                                
                                controller.mapView.addAnnotation(alert.alertAnnotation)
                                controller.mapView.selectAnnotation(annotation, animated: true)
                            }
                        }
                    })
                }
            }
        }
        
        // Delegates
        self.mapView.delegate = self
        
        // Custom notifications.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AKHeatMapViewController.locationObserver),
            name: NSNotification.Name(GlobalConstants.AKLocationUpdateNotificationName),
            object: nil
        )
        
        // Configure map.
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.mapView.userTrackingMode = MKUserTrackingMode.none
        
        AKHeatMapUtilityFunctions.addDefaultMapOverlays(self)
        
        if addRadarPin {
            self.radarAnnotation = AKRadarAnnotation()
            self.radarAnnotation?.coordinate = GlobalConstants.AKRadarOrigin
            self.radarAnnotation?.title = "Radar"
            self.mapView.addAnnotation(self.radarAnnotation!)
        }
        
        // Load all user defined alerts.
        GlobalFunctions.instance(false).AKDelay(2.0, task: {
            for alert in GlobalFunctions.instance(false).AKObtainMasterFile().user.userDefinedAlerts {
                self.mapView.addAnnotation(alert.alertAnnotation)
                self.mapView.selectAnnotation(alert.alertAnnotation, animated: true)
            }
        })
        
        // Add RainMap
        AKHeatMapUtilityFunctions.startRefreshTimer(self)
    }
}
