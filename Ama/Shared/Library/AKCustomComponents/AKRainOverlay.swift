import MapKit
import UIKit

class AKRainOverlay: NSObject, MKOverlay
{
    // MARK: Properties
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    let rainfallPoints: NSArray
    
    init(rainfallPoints: NSArray)
    {
        // Create rectangle for raindrop.
        // A raindrop is computed like:
        //      Center Coordinate + 2mts. radius
        // MARK: TODO Add support for only making the rectangle as stated above.
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
