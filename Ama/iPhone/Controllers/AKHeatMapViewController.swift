import CoreLocation
import Foundation
import Mapbox
import UIKit

class AKOriginPinAnnotation: MGLPointAnnotation {}
class AKOriginCircleAnnotation: MGLPointAnnotation {}
class AKHeatmapAnnotation: MGLPointAnnotation
{
    // MARK: Properties
    let rainfallIntensity: Double?
    
    init(rainfallIntensity: Double) {
        self.rainfallIntensity = rainfallIntensity
    }
}

class AKHeatMapViewController: AKCustomViewController, MGLMapViewDelegate
{
    // MARK: Properties
    private let originPinAnnotation = AKOriginPinAnnotation()
    private let originCircleAnnotation = AKOriginCircleAnnotation()
    
    // MARK: Outlets
    @IBOutlet var mapView: MGLMapView!
    
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
        self.mapView.zoomLevel = 8
        // self.mapView.styleURL = MGLStyle.satelliteStreetsStyleURL(withVersion: 9)
        self.mapView.styleURL = MGLStyle.lightStyleURL(withVersion: 9)
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.mapView.userTrackingMode = MGLUserTrackingMode.none
        
        // Add radar annotation.
        //  Radar Coordinates => -25.333079999999999, -57.523449999999997
        let origin = CLLocationCoordinate2DMake(-25.333079999999999, -57.523449999999997)
        if CLLocationCoordinate2DIsValid(origin) {
            self.mapView.setCenter(origin, zoomLevel: 8, animated: true)
            
            self.originCircleAnnotation.coordinate = origin
            self.originCircleAnnotation.title = "Cobertura Radar"
            self.mapView.addAnnotation(self.originCircleAnnotation)
            
            // Add PIN for user location.
            let annotation = MGLPointAnnotation()
            annotation.coordinate = origin
            annotation.title = "Radar"
            annotation.subtitle = String(format: "Lat: %f, Lng: %f", origin.latitude, origin.longitude)
            self.mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: MGLMapViewDelegate Implementation
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if annotation.isKind(of: AKOriginCircleAnnotation.self) {
            NSLog("=> ADDING A CIRCLE ANNOTATION.")
            
            let customView = MGLAnnotationImage(
                image: AKCircleImageWithRadius(100, strokeColor: UIColor.red, strokeAlpha: 1.0, fillColor: UIColor.red, fillAlpha: 0.15),
                reuseIdentifier: annotation.title!!
            )
            
            return customView
        }
        else if annotation.isKind(of: AKHeatmapAnnotation.self) {
            NSLog("=> ADDING A HEATMAP ANNOTATION.")
            
            let hma = annotation as! AKHeatmapAnnotation
            
            NSLog("%f", hma.rainfallIntensity!)
            
            let color = hma.rainfallIntensity!
            var useColor: UIColor?
            var alpha: Float?
            var radius: Int?
            switch color {
            case 1.0..<25.0:
                useColor = UIColor.purple
                alpha = 0.0
                radius = 4
                break
            case 25.0..<50.0:
                useColor = UIColor.blue
                alpha = 1.0
                radius = 4
                break
            case 50.0..<75.0:
                useColor = UIColor.cyan
                alpha = 1.0
                radius = 4
                break
            default:
                useColor = UIColor.red
                alpha = 1.0
                radius = 4
                break
            }
            
            let customView = MGLAnnotationImage(
                image: AKCircleImageWithRadius(radius!, strokeColor: UIColor.clear, strokeAlpha: 0.0, fillColor: useColor!, fillAlpha: alpha!),
                reuseIdentifier: annotation.title!!
            )
            
            return customView
        }
        else {
            NSLog("=> ADDING A DEFAULT ANNOTATION.")
            
            return nil
        }
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool { return true }
    
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
        let content: String?
        let data: [[String]]?
        var annotations: [AKHeatmapAnnotation] = []
        do {
            NSLog("=> READING WEATHER DATA FILE!")
            content = try String(contentsOfFile: Bundle.main.path(forResource: "2015-12-04--09%3A56%3A16,00", ofType:"ama")!, encoding: String.Encoding.utf8)
            data = CSwiftV(String: content!).rows
            
            var locations = [CLLocation]()
            var rainfallIntensities = [NSNumber]()
            for item in data! {
                let latitude = CLLocationDegrees(Double(item[1].components(separatedBy: ":")[0])!)
                let longitude = CLLocationDegrees(Double(item[1].components(separatedBy: ":")[1])!)
                let location = CLLocation(latitude: latitude, longitude: longitude)
                locations.append(location)
                
                let rainfallIntensity = Double(item[0])!
                rainfallIntensities.append(NSNumber(value: rainfallIntensity))
                
                // DEBUG:
                // NSLog("=> Latitude: \(latitude)\tLongitude: \(longitude)\tRI: \(weight)")
                
                // Add PIN for each dbZ.
                let annotation = AKHeatmapAnnotation(rainfallIntensity: rainfallIntensity)
                annotation.coordinate = location.coordinate
                annotation.title = String(format: "%f", rainfallIntensity)
                annotations.append(annotation)
            }
            
            self.mapView.addAnnotations(annotations)
            
            // let imageView = UIImageView(frame: self.mapView.frame)
            // imageView.contentMode = UIViewContentMode.center
            // imageView.image = AKHeatMap.heatMap(for: self.mapView, boost: 1.0, locations: locations, weights: weights)
            // self.mapView.addSubview(imageView)
        }
        catch {
            content = ""
            NSLog("=> ERROR READING *ATM.csv* FILE!", content!)
        }
    }
    
    func clearMap()
    {
        if (self.mapView.annotations?.count)! > 0 {
            self.mapView.removeAnnotations(self.mapView.annotations!)
        }
    }
}
