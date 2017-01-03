import MapKit
import UIKit

class AKRainfallPoint: NSObject
{
    // MARK: Properties
    let center: CLLocationCoordinate2D
    let intensity: Int
    let mapRect: MKMapRect
    
    init(center: CLLocationCoordinate2D, intensity: Int)
    {
        self.center = center
        self.intensity = intensity
        
        let bubbleRadius: Double = (Double(GlobalConstants.AKRaindropSize) * log2(Double(intensity)))
        
        let pointA = MKMapPointForCoordinate(
            GlobalFunctions.AKLocationWithBearing(
                bearing: (3 * M_PI) / 4,
                distanceMeters: bubbleRadius,
                origin: center
            )
        )
        let pointB = MKMapPointForCoordinate(
            GlobalFunctions.AKLocationWithBearing(
                bearing: (3 * M_PI) / 2,
                distanceMeters: bubbleRadius,
                origin: center
            )
        )
        self.mapRect = MKMapRectMake(
            fmin(pointA.x, pointB.x),
            fmin(pointA.y, pointB.y),
            fabs(pointA.x - pointB.x),
            fabs(pointA.y - pointB.y)
        )
    }
}
