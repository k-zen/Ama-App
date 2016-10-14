import CoreLocation
import Foundation
import Mapbox
import UIKit

class AKOriginPinAnnotation: MGLPointAnnotation {}
class AKOriginCircleAnnotation: MGLPointAnnotation {}
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
        self.mapView.zoomLevel = 10
        self.mapView.styleURL = MGLStyle.satelliteStreetsStyleURL(withVersion: 9)
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    // MARK: MGLMapViewDelegate Implementation
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: annotation.title!!) {
            return annotationImage
        }
        else {
            if annotation.isKind(of: AKOriginCircleAnnotation.self) {
                NSLog("=> ADDING A CIRCLE ANNOTATION.")
                
                let customView = MGLAnnotationImage(
                    image: AKCircleImageWithRadius(100, strokeColor: UIColor.red, strokeAlpha: 1.0, fillColor: UIColor.red, fillAlpha: 0.2),
                    reuseIdentifier: annotation.title!!
                )
                
                return customView
            }
            else {
                NSLog("=> ADDING A DEFAULT ANNOTATION.")
                return nil
            }
        }
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.title!!) {
            return annotationView
        }
        else {
            if (annotation.isKind(of: AKOriginPinAnnotation.self)) {
                NSLog("=> ADDING A PIN ANNOTATION.")
                return nil
            }
            else {
                NSLog("=> ADDING A DEFAULT ANNOTATION.")
                return nil
            }
        }
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool { return true }
    
    // MARK: Observers
    func locationUpdated()
    {
        OperationQueue.main.addOperation({ () -> Void in
            self.addDefaultAnnotations()
        })
    }
    
    // MARK: Miscellaneous
    func customSetup()
    {
        super.shouldCheckLoggedUser = false
        super.setup()
        
        // Custom notifications.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AKHeatMapViewController.locationUpdated),
            name: NSNotification.Name(GlobalConstants.AKLocationUpdateNotificationName),
            object: nil)
        
        // Delegates
        self.mapView.delegate = self
    }
    
    func addDefaultAnnotations()
    {
        // Add start annotation.
        let origin = AKDelegate().currentPosition
        if CLLocationCoordinate2DIsValid(origin) {
            self.mapView.setCenter(origin, zoomLevel: 10, animated: true)
            
            // self.originCircleAnnotation.coordinate = origin
            // self.originCircleAnnotation.title = "Origen_Radio"
            // self.mapView.addAnnotation(self.originCircleAnnotation)
            
            // Add PIN.
            let annotation = MGLPointAnnotation()
            annotation.coordinate = origin
            annotation.title = "Origen"
            annotation.subtitle = String(format: "Lat: %f, Lng: %f", origin.latitude, origin.longitude)
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func clearMap()
    {
        if (self.mapView.annotations?.count)! > 0 {
            self.mapView.removeAnnotations(self.mapView.annotations!)
        }
    }
}
