import MapKit
import UIKit

class AKRadarSpanOverlay: NSObject, MKOverlay
{
    // MARK: Properties
    var coordinate: GeoCoordinate
    var boundingMapRect: MKMapRect
    var radius: CLLocationDistance
    var title: String?
    
    init(center: GeoCoordinate, radius: CLLocationDistance)
    {
        self.coordinate = center
        self.radius = radius
        
        // Create rectangle for Paraguay.
        let pointA = MKMapPointForCoordinate(GlobalConstants.AKPYBoundsPointA)
        let pointB = MKMapPointForCoordinate(GlobalConstants.AKPYBoundsPointB)
        self.boundingMapRect = MKMapRectMake(
            fmin(pointA.x, pointB.x),
            fmin(pointA.y, pointB.y),
            fabs(pointA.x - pointB.x),
            fabs(pointA.y - pointB.y)
        )
    }
}

class AKRadarSpanLinesOverlay: MKPolyline {}
