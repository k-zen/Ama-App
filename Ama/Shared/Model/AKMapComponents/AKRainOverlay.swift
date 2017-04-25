import MapKit
import UIKit

class AKRainOverlay: NSObject, MKOverlay
{
    // MARK: Properties
    let coordinate: GeoCoordinate
    let boundingMapRect: MKMapRect
    let rainfallPoints: NSArray
    
    init(rainfallPoints: NSArray)
    {
        let pointA = MKMapPointForCoordinate(GlobalConstants.AKPYBoundsPointA)
        let pointB = MKMapPointForCoordinate(GlobalConstants.AKPYBoundsPointB)
        self.boundingMapRect = MKMapRectMake(
            fmin(pointA.x, pointB.x),
            fmin(pointA.y, pointB.y),
            fabs(pointA.x - pointB.x),
            fabs(pointA.y - pointB.y)
        )
        self.coordinate = GlobalConstants.AKPYBoundsPointA
        self.rainfallPoints = rainfallPoints
    }
}
