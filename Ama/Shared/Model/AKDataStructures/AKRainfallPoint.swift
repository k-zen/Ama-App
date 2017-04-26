import MapKit
import UIKit

class AKRainfallPoint: NSObject
{
    // MARK: Properties
    let debug = false
    let center: GeoCoordinate
    let intensity: RainIntensity
    let mapRect: MKMapRect
    
    init(center: GeoCoordinate, intensity: RainIntensity)
    {
        self.center = center
        self.intensity = intensity
        
        // Definitions:
        // ============
        //      + Map Points: Apple calls it map points to cartesian coordinates (X,Y) in a Mercator proyection. Being
        //      the origin, the geographic coordinates (λ = 90, φ = -180). Hence all values for X and Y are positive and
        //      the more south we move the bigger the value of Y and the more east we move the bigger the value of X.
        //
        //      + Map Rectangle: Apple calls it map rectangle to a rectangle in map points.
        
        // Formulae:
        // =========
        //      + Convert from geographic coordinates to cartesian coordinates in a Mercator proyection:
        //          X = R(φ - φ0)
        //          Y = R(ln(tan(π/4 + λ/2)))
        //
        //          For X coordinates:
        //          ==================
        //              In the case of Apple they use φ0 = -180, because that's the origin they use in their Mercator projection. So if we
        //              use that, then the more West you go the smaller the value of X and viceversa.
        //          For Y coordinates:
        //          ==================
        //              In the case of Apple I don't know which formula they use because for the formula above the X-Axis is located
        //              at the Ecuator, so the more North or South we go, the bigger the absolute value of Y will be.
        
        // How do we calculate the *map rectangle* for the raindrop...?
        // The idea is to calculate two *map points*:
        //      Point A = Is the North-West point at 45 degrees that lies at Radius meters from the origin.
        //      Point B = Is the South-East point at 45 degress that lies at Radius meters from the origin.
        // Then when we have both points, we find:
        //      1. The lowest X point and,
        //      2. The lowest Y point.
        //      3. We build a perfect square the size of ∆X and ∆Y.
        
        // The general idea here is that the higher the intensity, the bigger the square generated
        // for the map, that is why the radius is the product of the default size by the log2 of the intensity.
        let bubbleRadius = GlobalConstants.AKRaindropSize
        
        let pointA = MKMapPointForCoordinate(Func.AKLocationWithBearing(bearing: (3 * Double.pi) / 4, distanceMeters: bubbleRadius, origin: center))
        if self.debug {
            NSLog("=> INFO: POINT.A(x:%f,y:%f)", pointA.x, pointA.y)
        }
        
        let pointB = MKMapPointForCoordinate(Func.AKLocationWithBearing(bearing: (7 * Double.pi) / 4, distanceMeters: bubbleRadius, origin: center))
        if self.debug {
            NSLog("=> INFO: POINT.B(x:%f,y:%f)", pointB.x, pointB.y)
        }
        
        self.mapRect = MKMapRectMake(fmin(pointA.x, pointB.x), fmin(pointA.y, pointB.y), fabs(pointA.x - pointB.x), fabs(pointA.y - pointB.y))
    }
}
