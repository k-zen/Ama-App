import CoreLocation
import Foundation
import MapKit
import UIKit

class AKOriginAnnotation: MKPointAnnotation {}
class AKOriginOverlay: NSObject, MKOverlay
{
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var radius: CLLocationDistance
    var title: String?
    
    init(center: CLLocationCoordinate2D, radius: CLLocationDistance)
    {
        self.coordinate = center
        
        // Create rectangle for Paraguay.
        let pointA = MKMapPointForCoordinate(CLLocationCoordinate2DMake(-19.207429, -63.413086))
        let pointB = MKMapPointForCoordinate(CLLocationCoordinate2DMake(-27.722436, -52.778320))
        self.boundingMapRect = MKMapRectMake(fmin(pointA.x, pointB.x), fmin(pointA.y, pointB.y), fabs(pointA.x - pointB.x), fabs(pointA.y - pointB.y))
        
        self.radius = radius
    }
}

class AKHeatMapAnnotation: MKPointAnnotation
{
    // MARK: Properties
    var rainfallIntensity: Double
    
    init(rainfallIntensity: Double)
    {
        self.rainfallIntensity = rainfallIntensity
    }
}

class AKHeatMapViewController: AKCustomViewController, MKMapViewDelegate
{
    // MARK: Properties
    private var originAnnotation: AKOriginAnnotation?
    private var originOverlay: AKOriginOverlay?
    
    // MARK: Outlets
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
        
        // Configure map.
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.mapView.userTrackingMode = MKUserTrackingMode.none
        
        // Add radar annotation.
        // Radar Coordinates => -25.333079999999999, -57.523449999999997
        let origin = CLLocationCoordinate2DMake(-25.333079999999999, -57.523449999999997)
        if CLLocationCoordinate2DIsValid(origin) {
            self.mapView.setCenter(origin, animated: true)
            
            let span = MKCoordinateSpanMake(0.25, 0.25)
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: origin.latitude, longitude: origin.longitude), span: span)
            self.mapView.setRegion(region, animated: true)
            
            self.originOverlay = AKOriginOverlay(center: origin, radius: 50000)
            self.originOverlay?.title = "Cobertura Radar"
            // self.mapView.add(self.originOverlay!, level: MKOverlayLevel.aboveRoads)
            
            // Add PIN for user location.
            let annotation = MKPointAnnotation()
            annotation.coordinate = origin
            annotation.title = "Radar"
            annotation.subtitle = String(format: "Lat: %f, Lng: %f", origin.latitude, origin.longitude)
            self.mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: MKMapViewDelegate Implementation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation.isKind(of: AKHeatMapAnnotation.self) {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.title!!) {
                NSLog("=> DEQUEUEING HEATMAP ANNOTATION.")
                return annotationView
            }
            else {
                NSLog("=> NEW HEATMAP ANNOTATION.")
                
                let ann = annotation as! AKHeatMapAnnotation
                let hmc = AKGetInfoForRainfallIntensity(ri: ann.rainfallIntensity)
                let customView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotation.title!!)
                customView.image = AKSquareImage(0.75, strokeColor: UIColor.clear, strokeAlpha: 0.0, fillColor: hmc.color!, fillAlpha: hmc.alpha!)
                
                return customView
            }
        }
        else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        if overlay.isKind(of: AKOriginOverlay.self) {
            NSLog("=> NEW CIRCLE OVERLAY.")
            
            let ol = overlay as! AKOriginOverlay
            
            let customView = MKCircleRenderer(circle: MKCircle(center: ol.coordinate, radius: ol.radius))
            customView.fillColor = UIColor.red
            customView.alpha = 0.15
            customView.strokeColor = UIColor.red
            customView.lineWidth = 2.0
            
            return customView
        }
        else {
            NSLog("=> NEW DEFAULT OVERLAY.")
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationCanShowCallout annotation: MKAnnotation) -> Bool { return true }
    
    // MARK: Observers
    func locationUpdated()
    {
        OperationQueue.main.addOperation({ () -> Void in
            // Do nothing for the moment.
        })
    }
    
    // MARK: Miscellaneous
    func customSetup()
    {
        super.shouldCheckLoggedUser = false
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
        
        // Add HeatMap
        AKDelay(0.0, task: { Void -> Void in
            let content: String?
            let data: [[String]]?
            var annotations: [AKHeatMapAnnotation] = []
            do {
                NSLog("=> READING WEATHER DATA FILE!")
                content = try String(contentsOfFile: Bundle.main.path(forResource: "2015-12-04--09%3A56%3A16,00", ofType:"ama")!, encoding: String.Encoding.utf8)
                data = CSwiftV(String: content!).rows.sorted(by: { Float($0[0])! < Float($1[0])! })
                
                var locations = [CLLocation]()
                var rainfallIntensities = [NSNumber]()
                for item in data! {
                    let latitude = CLLocationDegrees(Double(item[1].components(separatedBy: ":")[0])!)
                    let longitude = CLLocationDegrees(Double(item[1].components(separatedBy: ":")[1])!)
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    locations.append(location)
                    
                    let rainfallIntensity = Double(item[0])!
                    rainfallIntensities.append(NSNumber(value: rainfallIntensity))
                    
                    // Add annotation for each rainfall intensity.
                    let annotation = AKHeatMapAnnotation(rainfallIntensity: rainfallIntensity)
                    annotation.coordinate = location.coordinate
                    annotation.title = AKGetInfoForRainfallIntensity(ri: rainfallIntensity).name!
                    
                    annotations.append(annotation)
                    
                    // DEBUG:
                    // NSLog("=> RI: %f", rainfallIntensity)
                }
                
                self.mapView.addAnnotations(annotations)
            }
            catch {
                content = ""
                NSLog("=> ERROR READING *ATM.csv* FILE!", content!)
            }
        })
    }
    
    func clearMap()
    {
        if self.mapView.annotations.count > 0 {
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
    }
}
