import AudioToolbox
import CoreLocation
import Foundation
import MapKit
import TSMessages
import UIKit

// MARK: Extensions
extension Int
{
    func modulo(_ divisor: Int) -> Int
    {
        var result = self % divisor
        if (result < 0) {
            result += divisor
        }
        
        return result
    }
}

extension UIImage
{
    static func fromColor(color: UIColor, frame: CGRect) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.withAlphaComponent(CGFloat(1.0)).cgColor)
        context?.setLineWidth(0)
        context?.fill(frame)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
}

extension String
{
    func splitOnNewLine () -> [String]
    {
        return self.components(separatedBy: CharacterSet.newlines)
    }
}

// MARK: Structures
struct GlobalConstants {
    static let AKDebug = true
    static let AKMasterFileName = "MasterFile.dat"
    static let AKNotificationBarDismissDelay = 4
    static let AKNotificationBarSound = 1057
    static let AKDefaultFont = "HelveticaNeue-CondensedBold"
    // Colors: https://github.com/morhetz/gruvbox
    static let AKDefaultBg = GlobalFunctions.AKHexColor(0x29282D)
    static let AKDefaultFg = GlobalFunctions.AKHexColor(0xFFFFFF)
    static let AKTabBarBg = GlobalConstants.AKDefaultBg
    static let AKTabBarTint = GlobalFunctions.AKHexColor(0xFFFFFF)
    static let AKOverlaysBg = GlobalConstants.AKDefaultBg
    static let AKDefaultViewBorderBg = GlobalFunctions.AKHexColor(0x8F8C87)
    static let AKUserAnnotationBg = GlobalFunctions.AKHexColor(0x458588)
    static let AKUserOverlayBg = GlobalFunctions.AKHexColor(0x689D6A)
    static let AKRadarAnnotationBg = GlobalFunctions.AKHexColor(0xD65D0E)
    // static let AKDisabledButtonBg = GlobalFunctions.AKHexColor(0xEEEEEE)
    // static let AKEnabledButtonBg = GlobalFunctions.AKHexColor(0x030C22)
    // static let AKTableHeaderCellBg = GlobalFunctions.AKHexColor(0x333333)
    // static let AKTableHeaderLeftBorderBg = GlobalFunctions.AKHexColor(0x72BF44)
    // static let AKHeaderLeftBorderBg = GlobalFunctions.AKHexColor(0x555555)
    // static let AKHeaderTopBorderBg = GlobalFunctions.AKHexColor(0x72BF44)
    static let AKButtonCornerRadius: CGFloat = 4.0
    static let AKDefaultBorderThickness = 2.0
    static let AKLocationUpdateInterval = 30
    static let AKLocationUpdateNotificationName = "AKLocationUpdate"
    static let AKRadarLatitude = -25.333079999999999
    static let AKRadarLongitude = -57.523449999999997
    static let AKDefaultLatitudeDelta = 0.45 // In degrees. 1 degree equals 111kms.
    static let AKDefaultLongitudeDelta = 0.45 // In degrees.
    static let AKLatitudeDegreeInKilometers = 111.0 // http://gis.stackexchange.com/questions/142326/calculating-longitude-length-in-miles
    static let AKPYBoundsPointA = CLLocationCoordinate2DMake(-19.207429, -63.413086)
    static let AKPYBoundsPointB = CLLocationCoordinate2DMake(-27.722436, -52.778320)
    static let AKRaindropSize: Float = 50.0 // This is the square side length in meters.
    static let AKMapTileTolerance: MKMapPoint = MKMapPointMake(5000.0, 5000.0)
    static let AKEarthRadius: Double = 6371.228 * 1000.0 // http://nsidc.org/data/ease/ease_grid.html
    static let AKRadarOrigin = CLLocationCoordinate2DMake(GlobalConstants.AKRadarLatitude, GlobalConstants.AKRadarLongitude)
    static let AKInvalidIntensity: Int = -1
}

struct AKRainfallIntensityColor {
    let color: UIColor
    let alpha: Float
    
    init(color: UIColor, alpha: Float) {
        self.color = color
        self.alpha = alpha
    }
}

// MARK: Global Enumerations
enum ErrorCodes: Int {
    case ConnectionToBackEndError = -1000
    case InvalidMIMEType = -1001
    case JSONProcessingError = -1002
}

enum Exceptions: Error {
    case notInitialized(msg: String)
    case emptyData(msg: String)
    case invalidLength(msg: String)
    case notValid(msg: String)
    case invalidJSON(msg: String)
}

enum HeatMapColor: UInt {
    case C01 = 0x118CF3
    case C02 = 0x0000F3
    case C03 = 0x22FF06
    case C04 = 0x19C204
    case C05 = 0x118102
    case C06 = 0xFFFF0B
    case C07 = 0xE0B508
    case C08 = 0xFD7C08
    case C09 = 0xFB0007
    case C10 = 0xCA0005
}

/// Zoom level in kilometers of span/viewport.
enum ZoomLevel: Double {
    /// 90Km
    case L01 = 90.0
    /// 80Km
    case L02 = 80.0
    /// 70Km
    case L03 = 70.0
    /// 60Km
    case L04 = 60.0
    /// 50Km
    case L05 = 50.0
    /// 40Km
    case L06 = 40.0
    /// 30Km
    case L07 = 30.0
    /// 20Km
    case L08 = 20.0
    /// 10Km
    case L09 = 10.0
    /// 01Km
    case L10 = 1.0
}

enum UnitOfLength: Int {
    case meter = 1
    case kilometer = 2
}

enum UnitOfTime: Int {
    case second = 1
    case minute = 2
    case hour = 3
}

enum UnitOfSpeed: Int {
    case metersPerSecond = 1
    case kilometersPerHour = 2
    case milesPerHour = 3
}

enum CustomBorderDecorationPosition: Int {
    case top = 0
    case right = 1
    case bottom = 2
    case left = 3
}

// MARK: Global Functions
class GlobalFunctions {
    static func AKAddBorderDeco(_ component: UIView, color: CGColor, thickness: Double, position: CustomBorderDecorationPosition) -> Void
    {
        let border = CALayer()
        border.backgroundColor = color
        switch position {
        case .top:
            border.frame = CGRect(x: 0, y: 0, width: component.frame.width, height: CGFloat(thickness))
            break
        case .right:
            border.frame = CGRect(x: (component.frame.width - CGFloat(thickness)), y: 0, width: CGFloat(thickness), height: component.frame.height)
            break
        case .bottom:
            border.frame = CGRect(x: 0, y: (component.frame.height - CGFloat(thickness)), width: component.frame.width, height: CGFloat(thickness))
            break
        case .left:
            border.frame = CGRect(x: 0, y: 0, width: CGFloat(thickness), height: component.frame.height)
            break
        }
        
        component.layer.addSublayer(border)
    }
    
    /// Computes the App's build version.
    ///
    /// - Returns: The App's build version.
    static func AKAppBuild() -> String
    {
        if let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return b
        }
        else {
            return "0"
        }
    }
    
    /// Computes the App's version.
    ///
    /// - Returns: The App's version.
    static func AKAppVersion() -> String
    {
        if let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return v
        }
        else {
            return "0"
        }
    }
    
    /// Executes a function with a delay.
    ///
    /// - Parameter delay: The delay.
    /// - Parameter task:  The function to execute.
    static func AKDelay(_ delay: Double, task: @escaping (Void) -> Void)
    {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: task)
    }
    
    /// Returns the App's delegate object.
    ///
    /// - Returns: The App's delegate object.
    static func AKDelegate() -> AKAppDelegate { return UIApplication.shared.delegate as! AKAppDelegate }
    
    /// Centers a map on a given coordinate and sets the viewport according to a radius.
    ///
    /// - Parameter mapView:   The mapview object.
    /// - Parameter location:  The coordinates.
    /// - Parameter zoomLevel: The zoom level to use.
    static func AKCenterMapOnLocation(mapView: MKMapView, location: CLLocationCoordinate2D, zoomLevel: ZoomLevel)
    {
        let span = MKCoordinateSpanMake(
            zoomLevel.rawValue / GlobalConstants.AKLatitudeDegreeInKilometers,
            zoomLevel.rawValue / GlobalConstants.AKLatitudeDegreeInKilometers
        )
        
        mapView.setCenter(location, animated: true)
        mapView.setRegion(
            MKCoordinateRegion(
                center: location,
                span: span
            ),
            animated: true
        )
    }
    
    /// Computes the distance between two points and returns the distance in meters.
    ///
    /// - Parameter pointA: Point A location.
    /// - Parameter pointB: Point B location.
    ///
    /// - Returns: TRUE if within range, FALSE otherwise.
    static func AKComputeDistanceBetweenTwoPoints(pointA: CLLocationCoordinate2D,
                                                  pointB: CLLocationCoordinate2D) -> CLLocationDistance
    {
        let pointA = CLLocation(latitude: pointA.latitude, longitude: pointA.longitude)
        let pointB = CLLocation(latitude: pointB.latitude, longitude: pointB.longitude)
        
        return pointA.distance(from: pointB)
    }
    
    /// Create a polygon with the form of a circle.
    ///
    /// - Parameter title:           The title of the polygon.
    /// - Parameter coordinate:      The location in coordinates of the center of the polygon.
    /// - Parameter withMeterRadius: The radius of the circle.
    ///
    /// - Returns: A polygon object in the form of a circle.
    static func AKCreateCircleForCoordinate(_ title: String, coordinate: CLLocationCoordinate2D, withMeterRadius: Double) -> MKPolygon
    {
        let degreesBetweenPoints = 8.0
        let numberOfPoints = floor(360.0 / degreesBetweenPoints)
        let distRadians: Double = withMeterRadius / GlobalConstants.AKEarthRadius
        let centerLatRadians: Double = coordinate.latitude * (M_PI / 180)
        let centerLonRadians: Double = coordinate.longitude * (M_PI / 180)
        var coordinates = [CLLocationCoordinate2D]()
        
        for index in 0 ..< Int(numberOfPoints) {
            let degrees: Double = Double(index) * Double(degreesBetweenPoints)
            let degreeRadians: Double = degrees * (M_PI / 180)
            let pointLatRadians: Double = asin(sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
            let pointLonRadians: Double = centerLonRadians + atan2(sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians))
            let pointLat: Double = pointLatRadians * (180 / M_PI)
            let pointLon: Double = pointLonRadians * (180 / M_PI)
            let point: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pointLat, pointLon)
            
            coordinates.append(point)
        }
        
        let polygon = MKPolygon(coordinates: &coordinates, count: Int(coordinates.count))
        polygon.title = title
        
        return polygon
    }
    
    /// Create an image with the form of a circle.
    ///
    /// - Parameter radius:      The radius of the circle.
    /// - Parameter strokeColor: The color of the stroke.
    /// - Parameter strokeAlpha: The alpha factor of the stroke.
    /// - Parameter fillColor:   The color of the fill.
    /// - Parameter fillAlpha:   The alpha factor of the fill.
    ///
    /// - Returns: An image object in the form of a circle.
    static func AKCircleImageWithRadius(_ radius: Int, strokeColor: UIColor, strokeAlpha: Float, fillColor: UIColor, fillAlpha: Float, lineWidth: CGFloat = 1) -> UIImage
    {
        let buffer = 2
        let rect = CGRect(x: 0, y: 0, width: radius * 2 + buffer, height: radius * 2 + buffer)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(fillColor.withAlphaComponent(CGFloat(fillAlpha)).cgColor)
        context?.setStrokeColor(strokeColor.withAlphaComponent(CGFloat(strokeAlpha)).cgColor)
        context?.setLineWidth(lineWidth)
        context?.fillEllipse(in: rect.insetBy(dx: CGFloat(buffer * 2), dy: CGFloat(buffer * 2)))
        context?.strokeEllipse(in: rect.insetBy(dx: CGFloat(buffer * 2), dy: CGFloat(buffer * 2)))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    
    static func AKExecuteInMainThread(code: @escaping (Void) -> Void)
    {
        OperationQueue.main.addOperation({ () -> Void in code() })
    }
    
    /// Returns the associated color for an interval of rainfall intensity.
    ///
    /// - Parameter ri: The value of rainfall intensity.
    ///
    /// - Returns: A color object.
    static func AKGetInfoForRainfallIntensity(ri: Int) -> AKRainfallIntensityColor
    {
        switch ri {
        case 1 ..< 25:
            return AKRainfallIntensityColor(color: AKHexColor(HeatMapColor.C01.rawValue), alpha: 1.00)
        case 25 ..< 50:
            return AKRainfallIntensityColor(color: AKHexColor(HeatMapColor.C02.rawValue), alpha: 1.00)
        case 50 ..< 75:
            return AKRainfallIntensityColor(color: AKHexColor(HeatMapColor.C03.rawValue), alpha: 1.00)
        case 75 ..< 100:
            return AKRainfallIntensityColor(color: AKHexColor(HeatMapColor.C04.rawValue), alpha: 1.00)
        case 100 ..< 125:
            return AKRainfallIntensityColor(color: AKHexColor(HeatMapColor.C05.rawValue), alpha: 1.00)
        case 125 ..< 150:
            return AKRainfallIntensityColor(color: AKHexColor(HeatMapColor.C06.rawValue), alpha: 1.00)
        case 150 ..< 175:
            return AKRainfallIntensityColor(color: AKHexColor(HeatMapColor.C07.rawValue), alpha: 1.00)
        case 175 ..< 200:
            return AKRainfallIntensityColor(color: AKHexColor(HeatMapColor.C08.rawValue), alpha: 1.00)
        case 200 ..< 225:
            return AKRainfallIntensityColor(color: AKHexColor(HeatMapColor.C09.rawValue), alpha: 1.00)
        case 225 ..< Int.max:
            return AKRainfallIntensityColor(color: AKHexColor(HeatMapColor.C10.rawValue), alpha: 1.00)
        default:
            return AKRainfallIntensityColor(color: UIColor.clear, alpha: 0.0)
        }
    }
    
    /// Computes and generates a **UIColor** object based
    /// on it's hexadecimal representation.
    ///
    /// - Parameter hex: The hexadecimal representation of the color.
    ///
    /// - Returns: A **UIColor** object.
    static func AKHexColor(_ hex: UInt) -> UIColor
    {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat((hex) & 0xFF) / 255.0
        
        return UIColor.init(red: red, green: green, blue: blue, alpha: 1)
    }
    
    /// Returns a geographic location (lat, long) from an original location with bearing and the
    /// distance computed in meters from the original location.
    ///
    /// - Parameter bearing: The bearing in radians.
    /// - Parameter distanceMeters: The distance from point A to Z in meters.
    /// - Parameter origin: The original location. (Point A)
    ///
    /// - Returns: A location object (Point Z).
    static func AKLocationWithBearing(bearing: Double, distanceMeters: Double, origin: CLLocationCoordinate2D) -> CLLocationCoordinate2D
    {
        let distRadians: Double = distanceMeters / GlobalConstants.AKEarthRadius
        
        let lat1: Double = origin.latitude * (M_PI / 180)
        let lon1: Double = origin.longitude * (M_PI / 180)
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * (180 / M_PI), longitude: lon2 * (180 / M_PI))
    }
    
    /// Returns the App's master file object.
    ///
    /// - Returns The App's master file.
    static func AKObtainMasterFile() -> AKMasterFile
    {
        return GlobalFunctions.AKDelegate().masterFile
    }
    
    static func AKPresentTopMessage(_ presenter: UIViewController!, type: TSMessageNotificationType, message: String!)
    {
        GlobalFunctions.AKExecuteInMainThread {
            let title: String
            switch type {
            case .message:
                title = "Información"
            case .warning:
                title = "Advertencia"
            case .error:
                title = "Error"
            case .success:
                title = "👍"
            }
            
            TSMessage.showNotification(
                in: presenter,
                title: title,
                subtitle: message,
                image: nil,
                type: type,
                duration: TimeInterval(GlobalConstants.AKNotificationBarDismissDelay),
                callback: nil,
                buttonTitle: nil,
                buttonCallback: {},
                at: TSMessageNotificationPosition.top,
                canBeDismissedByUser: true
            )
            AudioServicesPlaySystemSound(UInt32(GlobalConstants.AKNotificationBarSound))
        }
    }
    
    /// Executes code and measures the execution time.
    ///
    /// - Parameter title: The title of the operation.
    /// - Parameter operation: The code to be executed in a closure.
    static func AKPrintTimeElapsedWhenRunningCode(title: String, operation: () -> ())
    {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        NSLog("=> INFO: TIME ELAPSED FOR \(title): %.4f seconds.", timeElapsed)
    }
    
    static func AKRangeFromNSRange(_ nsRange: NSRange, forString str: String) -> Range<String.Index>?
    {
        let fromUTF16 = str.utf16.startIndex.advanced(by: nsRange.location)
        let toUTF16 = fromUTF16.advanced(by: nsRange.length)
        
        if let from = String.Index(fromUTF16, within: str), let to = String.Index(toUTF16, within: str) {
            return from ..< to
        }
        
        return nil
    }
    
    /// Create an image with the form of a square.
    ///
    /// - Parameter side:        The length of the side.
    /// - Parameter strokeColor: The color of the stroke.
    /// - Parameter strokeAlpha: The alpha factor of the stroke.
    /// - Parameter fillColor:   The color of the fill.
    /// - Parameter fillAlpha:   The alpha factor of the fill.
    ///
    /// - Returns: An image object in the form of a square.
    static func AKSquareImage(_ sideLength: Double, strokeColor: UIColor, strokeAlpha: Float, fillColor: UIColor, fillAlpha: Float) -> UIImage
    {
        let buffer = 2.0
        let rect = CGRect(x: 0, y: 0, width: sideLength * 2.0 + buffer, height: sideLength * 2.0 + buffer)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(fillColor.withAlphaComponent(CGFloat(fillAlpha)).cgColor)
        context?.setStrokeColor(strokeColor.withAlphaComponent(CGFloat(strokeAlpha)).cgColor)
        context?.setLineWidth(1)
        context?.fill(rect)
        context?.stroke(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    /// Converts the zoom scale provided by MapKit to a
    /// standard scale.
    ///
    /// - Parameter zoomScale: The zoom value as provided by MapKit.
    /// - Parameter debug: Show debug info.
    ///
    /// - Returns: A zoom level.
    static func AKZoomScaleConvert(zoomScale: MKZoomScale, debug: Bool) -> Int
    {
        let maxZoom: Int = Int(log2(MKMapSizeWorld.width / 256.0))
        if debug { NSLog("=> INFO: MAX ZOOM: %i", maxZoom) }
        let currZoom: Int = Int(log2f(Float(zoomScale)))
        if debug { NSLog("=> INFO: CURRENT ZOOM: %i", currZoom) }
        
        return max(1, maxZoom + currZoom)
    }
}
