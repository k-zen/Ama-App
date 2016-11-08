import UIKit

class AKRainfallPoint: NSObject
{
    // MARK: Properties
    let center: CLLocationCoordinate2D
    let intensity: Double
    let mapRect: MKMapRect
    
    init(center: CLLocationCoordinate2D, intensity: Double)
    {
        self.center = center
        self.intensity = intensity
        
        let pointA = MKMapPointForCoordinate(
            AKLocationWithBearing(bearing: (3 * M_PI) / 4, distanceMeters: Double(GlobalConstants.AKRaindropSize), origin: center)
        )
        let pointB = MKMapPointForCoordinate(
            AKLocationWithBearing(bearing: (7 * M_PI) / 4, distanceMeters: Double(GlobalConstants.AKRaindropSize), origin: center)
        )
        self.mapRect = MKMapRectMake(
            fmin(pointA.x, pointB.x),
            fmin(pointA.y, pointB.y),
            fabs(pointA.x - pointB.x),
            fabs(pointA.y - pointB.y)
        )
    }
}
