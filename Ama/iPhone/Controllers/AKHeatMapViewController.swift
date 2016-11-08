import CoreLocation
import Foundation
import MapKit
import UIKit

class AKRadarAnnotation: MKPointAnnotation {}
class AKUserAnnotation: MKPointAnnotation {}

class AKHeatMapViewController: AKCustomViewController, MKMapViewDelegate
{
    // MARK: Properties
    private let addRadarOverlay = false
    private let addRadarPin = false
    private let addUserOverlay = true
    private let addUserPin = true
    private let radarAnnotation: AKRadarAnnotation = AKRadarAnnotation()
    private let userAnnotation: AKUserAnnotation = AKUserAnnotation()
    private var radarOverlay: AKRadarSpanOverlay?
    private var userOverlay: AKUserAreaOverlay?
    
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
                self.radarOverlay = AKRadarSpanOverlay(center: origin, radius: 50000)
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
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        if overlay.isKind(of: AKRadarSpanOverlay.self) {
            let ol = overlay as! AKRadarSpanOverlay
            
            let customView = MKCircleRenderer(circle: MKCircle(center: ol.coordinate, radius: ol.radius))
            customView.fillColor = UIColor.red
            customView.alpha = 0.05
            customView.strokeColor = UIColor.red
            customView.lineWidth = 1.0
            
            return customView
        }
        else if overlay.isKind(of: AKUserAreaOverlay.self) {
            let ol = overlay as! AKUserAreaOverlay
            
            let customView = MKCircleRenderer(circle: MKCircle(center: ol.coordinate, radius: ol.radius))
            customView.fillColor = AKHexColor(0x4DBCE9)
            customView.alpha = 0.25
            customView.strokeColor = AKHexColor(0x4DBCE9)
            customView.lineWidth = 2.0
            
            return customView
        }
        else if overlay.isKind(of: AKRainOverlay.self) {
            let ol = overlay as! AKRainOverlay
            return AKRainOverlayRenderer(overlay: overlay, rainfallPoints: ol.rainfallPoints as! [AKRainfallPoint])
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
                self.userOverlay = AKUserAreaOverlay(center: coordinate, radius: 5000)
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
        let frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        self.img01.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C01.rawValue), frame: frame)
        self.img02.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C02.rawValue), frame: frame)
        self.img03.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C03.rawValue), frame: frame)
        self.img04.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C04.rawValue), frame: frame)
        self.img05.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C05.rawValue), frame: frame)
        self.img06.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C06.rawValue), frame: frame)
        self.img07.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C07.rawValue), frame: frame)
        self.img08.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C08.rawValue), frame: frame)
        self.img09.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C09.rawValue), frame: frame)
        self.img10.image = UIImage.fromColor(color: AKHexColor(HeatMapColor.C10.rawValue), frame: frame)
        
        // Add HeatMap
        AKDelay(0.0, task: { Void -> Void in
            let content: String?
            let data: [[String]]?
            let rainfallPoints: NSMutableArray = NSMutableArray()
            do {
                NSLog("=> READING WEATHER DATA FILE!")
                content = try String(contentsOfFile: Bundle.main.path(forResource: "2015-12-04--09%3A56%3A16,00", ofType:"ama")!, encoding: String.Encoding.utf8)
                data = CSwiftV(String: content!).rows.sorted(by: { Float($0[0])! < Float($1[0])! })
                for item in data! {
                    let lat = CLLocationDegrees(Double(item[1].components(separatedBy: ":")[0])!)
                    let lon = CLLocationDegrees(Double(item[1].components(separatedBy: ":")[1])!)
                    let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    
                    let rainfallIntensity = Double(item[0])!
                    
                    rainfallPoints.add(AKRainfallPoint.init(center: location, intensity: rainfallIntensity))
                }
                
                self.mapView.add(AKRainOverlay(rainfallPoints: rainfallPoints), level: MKOverlayLevel.aboveRoads)
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
