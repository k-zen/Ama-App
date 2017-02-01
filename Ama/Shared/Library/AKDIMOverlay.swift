import MapKit
import UIKit

class AKDIMOverlay: NSObject, MKOverlay
{
    // MARK: Properties
    let coordinate: GeoCoordinate
    let boundingMapRect: MKMapRect
    
    init(mapView: MKMapView)
    {
        self.boundingMapRect = MKMapRectWorld
        self.coordinate = mapView.centerCoordinate
    }
}
