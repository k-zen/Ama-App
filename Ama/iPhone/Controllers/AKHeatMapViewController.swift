import CoreLocation
import Foundation
import MapKit
import UIKit

class AKRadarAnnotation: MKPointAnnotation {}
class AKUserAnnotation: MKPointAnnotation {}

class AKRadarOverlay: NSObject, MKOverlay
{
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var radius: CLLocationDistance
    var title: String?
    
    init(center: CLLocationCoordinate2D, radius: CLLocationDistance)
    {
        self.coordinate = center
        
        // Create rectangle for Paraguay.
        let pointA = MKMapPointForCoordinate(GlobalConstants.AKPYBoundsPointA)
        let pointB = MKMapPointForCoordinate(GlobalConstants.AKPYBoundsPointB)
        self.boundingMapRect = MKMapRectMake(fmin(pointA.x, pointB.x), fmin(pointA.y, pointB.y), fabs(pointA.x - pointB.x), fabs(pointA.y - pointB.y))
        
        self.radius = radius
    }
}
class AKUserOverlay: NSObject, MKOverlay
{
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var radius: CLLocationDistance
    var title: String?
    
    init(center: CLLocationCoordinate2D, radius: CLLocationDistance)
    {
        self.coordinate = center
        
        // Create rectangle for Paraguay.
        let pointA = MKMapPointForCoordinate(GlobalConstants.AKPYBoundsPointA)
        let pointB = MKMapPointForCoordinate(GlobalConstants.AKPYBoundsPointB)
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
    private let addRadarOverlay = false
    private let addRadarPin = false
    private let addUserOverlay = true
    private let addUserPin = true
    private let radarAnnotation: AKRadarAnnotation = AKRadarAnnotation()
    private let userAnnotation: AKUserAnnotation = AKUserAnnotation()
    private var radarOverlay: AKRadarOverlay?
    private var userOverlay: AKUserOverlay?
    
    // MARK: Outlets
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
        
        // Configure map.
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.mapView.userTrackingMode = MKUserTrackingMode.none
        
        // Add radar annotation.
        let origin = CLLocationCoordinate2DMake(GlobalConstants.AKRadarLatitude, GlobalConstants.AKRadarLongitude)
        if CLLocationCoordinate2DIsValid(origin) {
            self.mapView.setCenter(origin, animated: true)
            
            let span = MKCoordinateSpanMake(GlobalConstants.AKDefaultLatitudeDelta, GlobalConstants.AKDefaultLongitudeDelta)
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: origin.latitude, longitude: origin.longitude), span: span)
            self.mapView.setRegion(region, animated: true)
            
            if addRadarOverlay {
                self.radarOverlay = AKRadarOverlay(center: origin, radius: 50000)
                self.radarOverlay?.title = "Cobertura Radar"
                self.mapView.add(self.radarOverlay!, level: MKOverlayLevel.aboveRoads)
            }
            
            if addRadarPin {
                self.radarAnnotation.coordinate = origin
                self.radarAnnotation.title = "Radar"
                self.radarAnnotation.subtitle = String(format: "Lat: %f, Lng: %f", origin.latitude, origin.longitude)
                self.mapView.addAnnotation(self.radarAnnotation)
            }
        }
    }
    
    // MARK: MKMapViewDelegate Implementation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation.isKind(of: AKHeatMapAnnotation.self) {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.title!!) {
                // NSLog("=> DEQUEUEING HEATMAP ANNOTATION.")
                return annotationView
            }
            else {
                // NSLog("=> NEW HEATMAP ANNOTATION.")
                
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
        if overlay.isKind(of: AKRadarOverlay.self) {
            let ol = overlay as! AKRadarOverlay
            
            let customView = MKCircleRenderer(circle: MKCircle(center: ol.coordinate, radius: ol.radius))
            customView.fillColor = UIColor.red
            customView.alpha = 0.05
            customView.strokeColor = UIColor.red
            customView.lineWidth = 1.0
            
            return customView
        }
        else if overlay.isKind(of: AKUserOverlay.self) {
            let ol = overlay as! AKUserOverlay
            
            let customView = MKCircleRenderer(circle: MKCircle(center: ol.coordinate, radius: ol.radius))
            customView.fillColor = AKHexColor(0x4DBCE9)
            customView.alpha = 0.45
            customView.strokeColor = AKHexColor(0x4DBCE9)
            customView.lineWidth = 1.0
            
            return customView
        }
        else {
            // NSLog("=> NEW DEFAULT OVERLAY.")
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationCanShowCallout annotation: MKAnnotation) -> Bool { return true }
    
    // MARK: Observers
    func locationUpdated()
    {
        OperationQueue.main.addOperation({ () -> Void in
            let coordinate = AKDelegate().currentPosition
            
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
                self.userOverlay = AKUserOverlay(center: coordinate, radius: 5000)
                self.userOverlay?.title = "Cobertura Usuario"
                self.mapView.add(self.userOverlay!, level: MKOverlayLevel.aboveRoads)
            }
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
        
        // Create Legend
        self.img01.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C01.rawValue), frame: self.img01.frame)
        self.img02.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C02.rawValue), frame: self.img02.frame)
        self.img03.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C03.rawValue), frame: self.img03.frame)
        self.img04.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C04.rawValue), frame: self.img04.frame)
        self.img05.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C05.rawValue), frame: self.img05.frame)
        self.img06.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C06.rawValue), frame: self.img06.frame)
        self.img07.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C07.rawValue), frame: self.img07.frame)
        self.img08.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C08.rawValue), frame: self.img08.frame)
        self.img09.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C09.rawValue), frame: self.img09.frame)
        self.img10.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C10.rawValue), frame: self.img10.frame)
        
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
