import AudioToolbox
import CoreLocation
import Foundation
import MapKit
import TSMessages
import UIKit

// MARK: Typealias
typealias ViewBlock = (_ view : UIView) -> Bool
typealias JSONObject = [String : Any]
typealias JSONObjectArray = [Any]
typealias JSONObjectStringArray = [String]
typealias RainIntensity = Int16
typealias GeoCoordinate = CLLocationCoordinate2D
typealias Latitude = Double
typealias Longitude = Double
typealias User = AKUser
typealias Alert = AKAlert

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

extension UIView
{
    func loopViewHierarchy(block : ViewBlock?)
    {
        if block?(self) ?? true {
            for subview in self.subviews {
                subview.loopViewHierarchy(block: block)
            }
        }
    }
}

// MARK: Structures
struct GlobalConstants {
    static let AKDebug = true
    static let AKMasterFileName = "MasterFile.dat"
    static let AKNotificationBarDismissDelay = 2.0
    static let AKNotificationBarSound = 1057
    static let AKDefaultFont = "HelveticaNeue-Thin"
    static let AKRedColor_1 = GlobalFunctions.instance(false).AKHexColor(0xDF3732)
    static let AKDefaultBg = GlobalFunctions.instance(false).AKHexColor(0x29282D)
    static let AKDefaultFg = GlobalFunctions.instance(false).AKHexColor(0xFFFFFF)
    static let AKTabBarBg = GlobalConstants.AKDefaultBg
    static let AKTabBarTintNormal = GlobalFunctions.instance(false).AKHexColor(0xFFFFFF)
    static let AKTabBarTintSelected = GlobalFunctions.instance(false).AKHexColor(0x0088CC)
    static let AKDefaultTextfieldBorderBg = GlobalFunctions.instance(false).AKHexColor(0x999999)
    static let AKOverlaysBg = GlobalConstants.AKDefaultBg
    static let AKDefaultViewBorderBg = GlobalFunctions.instance(false).AKHexColor(0x000000)
    static let AKDefaultFloatingViewBorderBg = UIColor.black
    static let AKUserAnnotationBg = GlobalConstants.AKRedColor_1
    static let AKAlertAnnotationBg = UIColor.orange
    static let AKUserOverlayBg = GlobalConstants.AKRedColor_1
    static let AKRadarAnnotationBg = UIColor.green
    static let AKDisabledButtonBg = GlobalFunctions.instance(false).AKHexColor(0x999999)
    static let AKEnabledButtonBg = GlobalConstants.AKRedColor_1
    static let AKTableHeaderCellBg = UIColor.black
    static let AKTableHeaderLeftBorderBg = GlobalFunctions.instance(false).AKHexColor(0xEBDBB2)
    static let AKTableCellBg = GlobalConstants.AKDefaultBg
    static let AKTableCellLeftBorderBg = GlobalConstants.AKTableHeaderLeftBorderBg
    static let AKButtonCornerRadius: CGFloat = 4.0
    static let AKDefaultBorderThickness = 1.5
    static let AKLocationUpdateInterval = 30
    static let AKLocationUpdateNotificationName = "AKLocationUpdate"
    static let AKRadarLatitude = -25.333079999999999
    static let AKRadarLongitude = -57.523449999999997
    static let AKLatitudeDegreeInKilometers = 111.0 // http://gis.stackexchange.com/questions/142326/calculating-longitude-length-in-miles
    static let AKPYBoundsPointA = GeoCoordinate(latitude: -19.207429, longitude: -63.413086)
    static let AKPYBoundsPointB = GeoCoordinate(latitude: -27.722436, longitude: -52.778320)
    static let AKRaindropSize: Double = 50.0 // This is the square side length in meters.
    static let AKMapTileTolerance: MKMapPoint = MKMapPointMake(5000.0, 5000.0)
    static let AKEarthRadius: Double = 6371.228 * 1000.0 // http://nsidc.org/data/ease/ease_grid.html
    static let AKRadarOrigin = GeoCoordinate(latitude: GlobalConstants.AKRadarLatitude, longitude: GlobalConstants.AKRadarLongitude)
    static let AKInvalidIntensity: RainIntensity = -1
    static let AKMaxUserDefinedAlerts: Int = 3
    static let AKEmptyPhoneNumberPrefix = "00"
    static let AKEmptyPhoneNumber = "000000"
    static let AKMaxUsernameLength = 12
    static let AKMinUsernameLength = 3
    static let AKMaxPhoneNumberLength = 8
    static let AKMinPhoneNumberLength = 8
    static let AKDefaultZoomLevel = ZoomLevel.L08
    static let AKDIMOverlayAlpha = 0.60
    static let AKAmaServerAddress = "http://190.128.205.74:8102"
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
    case notInitialized(String)
    case emptyData(String)
    case invalidLength(String)
    case notValid(String)
    case invalidJSON(String)
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
    private var showDebugInformation = false
    
    ///
    /// Creates and configures a new instance of the class. Use this method for
    /// calling all other functions.
    ///
    static func instance(_ showDebugInformation: Bool) -> GlobalFunctions
    {
        let instance = GlobalFunctions()
        instance.showDebugInformation = showDebugInformation
        
        return instance
    }
    
    ///
    /// Adds a border line decoration to any UIView or descendant of UIView.
    ///
    /// - Parameter component: The view where to add the border.
    /// - Parameter color: The color of the border.
    /// - Parameter thickness: The thickness of the border.
    /// - Parameter position: It can be 4 types: top, bottom, left, right.
    ///
    func AKAddBorderDeco(_ component: UIView, color: CGColor, thickness: Double, position: CustomBorderDecorationPosition)
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
    
    ///
    /// Computes the App's build version.
    ///
    /// - Returns: The App's build version.
    ///
    func AKAppBuild() -> String
    {
        if let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return b
        }
        else {
            return "0"
        }
    }
    
    ///
    /// Computes the App's version.
    ///
    /// - Returns: The App's version.
    ///
    func AKAppVersion() -> String
    {
        if let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return v
        }
        else {
            return "0"
        }
    }
    
    ///
    /// Executes a function with a delay.
    ///
    /// - Parameter delay: The delay.
    /// - Parameter isMain: Should we launch the task in the main thread...?
    /// - Parameter task:  The function to execute.
    ///
    func AKDelay(_ delay: Double, isMain: Bool = true, task: @escaping (Void) -> Void)
    {
        if isMain {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: task)
        }
        else {
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: task)
        }
    }
    
    ///
    /// Returns the App's delegate object.
    ///
    /// - Returns: The App's delegate object.
    ///
    func AKDelegate() -> AKAppDelegate { return UIApplication.shared.delegate as! AKAppDelegate }
    
    ///
    /// Adds a toolbar to the keyboard with a single button to close it down.
    ///
    /// - Parameter textControl: The control where to add the keyboard.
    /// - Parameter controller: The view controller that owns the control.
    ///
    func AKAddDoneButtonKeyboard(_ textControl: AnyObject, controller: AKCustomViewController) {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.frame = CGRect(x: 0, y: 0, width: textControl.bounds.width, height: 30)
        keyboardToolbar.barTintColor = UIColor.black
        
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let doneBarButton = UIBarButtonItem(title: "Cerrar Teclado", style: .done, target: controller, action: #selector(AKCustomViewController.tap(_:)))
        doneBarButton.setTitleTextAttributes(
            [
                NSFontAttributeName : UIFont(name: GlobalConstants.AKDefaultFont, size: 16.0)!,
                NSForegroundColorAttributeName: UIColor.white
            ], for: UIControlState.normal
        )
        
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        
        if textControl is UITextField {
            let textControlTmp = textControl as! UITextField
            textControlTmp.inputAccessoryView = keyboardToolbar
        }
        else if textControl is UITextView {
            let textControlTmp = textControl as! UITextView
            textControlTmp.inputAccessoryView = keyboardToolbar
        }
    }
    
    ///
    /// Centers a map on a given coordinate and sets the viewport according to a radius.
    ///
    /// - Parameter mapView:   The mapview object.
    /// - Parameter location:  The coordinates.
    /// - Parameter zoomLevel: The zoom level to use.
    ///
    func AKCenterMapOnLocation(mapView: MKMapView, location: GeoCoordinate, zoomLevel: ZoomLevel)
    {
        GlobalFunctions.instance(false).AKExecuteInMainThread {
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
    }
    
    ///
    /// Computes the distance between two points and returns the distance in meters.
    ///
    /// - Parameter pointA: Point A location.
    /// - Parameter pointB: Point B location.
    ///
    /// - Returns: TRUE if within range, FALSE otherwise.
    ///
    func AKComputeDistanceBetweenTwoPoints(pointA: GeoCoordinate, pointB: GeoCoordinate) -> CLLocationDistance
    {
        let pointA = CLLocation(latitude: pointA.latitude, longitude: pointA.longitude)
        let pointB = CLLocation(latitude: pointB.latitude, longitude: pointB.longitude)
        
        return pointA.distance(from: pointB)
    }
    
    ///
    /// Create a polygon with the form of a circle.
    ///
    /// - Parameter title:           The title of the polygon.
    /// - Parameter coordinate:      The location in coordinates of the center of the polygon.
    /// - Parameter withMeterRadius: The radius of the circle.
    ///
    /// - Returns: A polygon object in the form of a circle.
    ///
    func AKCreateCircleForCoordinate(_ title: String, coordinate: GeoCoordinate, withMeterRadius: Double) -> MKPolygon
    {
        let degreesBetweenPoints = 8.0
        let numberOfPoints = floor(360.0 / degreesBetweenPoints)
        let distRadians: Double = withMeterRadius / GlobalConstants.AKEarthRadius
        let centerLatRadians: Double = coordinate.latitude * (Double.pi / 180)
        let centerLonRadians: Double = coordinate.longitude * (Double.pi / 180)
        var coordinates = [GeoCoordinate]()
        
        for index in 0 ..< Int(numberOfPoints) {
            let degrees: Double = Double(index) * Double(degreesBetweenPoints)
            let degreeRadians: Double = degrees * (Double.pi / 180)
            let pointLatRadians: Double = asin(sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
            let pointLonRadians: Double = centerLonRadians + atan2(sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians))
            let pointLat: Double = pointLatRadians * (180 / Double.pi)
            let pointLon: Double = pointLonRadians * (180 / Double.pi)
            let point = GeoCoordinate(latitude: pointLat, longitude: pointLon)
            
            coordinates.append(point)
        }
        
        let polygon = MKPolygon(coordinates: &coordinates, count: Int(coordinates.count))
        polygon.title = title
        
        return polygon
    }
    
    ///
    /// Create an image with the form of a circle.
    ///
    /// - Parameter radius:      The radius of the circle.
    /// - Parameter strokeColor: The color of the stroke.
    /// - Parameter strokeAlpha: The alpha factor of the stroke.
    /// - Parameter fillColor:   The color of the fill.
    /// - Parameter fillAlpha:   The alpha factor of the fill.
    ///
    /// - Returns: An image object in the form of a circle.
    ///
    func AKCircleImageWithRadius(_ radius: Int, strokeColor: UIColor, strokeAlpha: Float, fillColor: UIColor, fillAlpha: Float, lineWidth: CGFloat = 1) -> UIImage
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
    
    ///
    /// Executes some code inside a closure but in the main thread.
    ///
    /// - Parameter code: The code to be executed in the main thread.
    ///
    func AKExecuteInMainThread(code: @escaping (Void) -> Void)
    {
        OperationQueue.main.addOperation({ () -> Void in code() })
    }
    
    ///
    /// Returns the associated color for an interval of rainfall intensity.
    ///
    /// - Parameter ri: The value of rainfall intensity.
    ///
    /// - Returns: A color object.
    ///
    func AKGetInfoForRainfallIntensity(ri: RainIntensity) -> AKRainfallIntensityColor
    {
        switch ri {
        case 1 ..< 25:
            return AKRainfallIntensityColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C01.rawValue), alpha: 0.50)
        case 25 ..< 50:
            return AKRainfallIntensityColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C02.rawValue), alpha: 0.50)
        case 50 ..< 75:
            return AKRainfallIntensityColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C03.rawValue), alpha: 0.50)
        case 75 ..< 100:
            return AKRainfallIntensityColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C04.rawValue), alpha: 0.50)
        case 100 ..< 125:
            return AKRainfallIntensityColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C05.rawValue), alpha: 0.50)
        case 125 ..< 150:
            return AKRainfallIntensityColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C06.rawValue), alpha: 0.50)
        case 150 ..< 175:
            return AKRainfallIntensityColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C07.rawValue), alpha: 0.50)
        case 175 ..< 200:
            return AKRainfallIntensityColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C08.rawValue), alpha: 0.50)
        case 200 ..< 225:
            return AKRainfallIntensityColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C09.rawValue), alpha: 0.50)
        case 225 ..< RainIntensity.max:
            return AKRainfallIntensityColor(color: GlobalFunctions.instance(false).AKHexColor(HeatMapColor.C10.rawValue), alpha: 0.50)
        default:
            return AKRainfallIntensityColor(color: UIColor.clear, alpha: 0.0)
        }
    }
    
    ///
    /// Computes and generates a **UIColor** object based
    /// on it's hexadecimal representation.
    ///
    /// - Parameter hex: The hexadecimal representation of the color.
    ///
    /// - Returns: A **UIColor** object.
    ///
    func AKHexColor(_ hex: UInt) -> UIColor
    {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat((hex) & 0xFF) / 255.0
        
        return UIColor.init(red: red, green: green, blue: blue, alpha: 1)
    }
    
    ///
    /// Returns a geographic location (lat, long) from an original location with bearing and the
    /// distance computed in meters from the original location.
    ///
    /// - Parameter bearing: The bearing in radians.
    /// - Parameter distanceMeters: The distance from point A to Z in meters.
    /// - Parameter origin: The original location. (Point A)
    ///
    /// - Returns: A location object (Point Z).
    ///
    func AKLocationWithBearing(bearing: Double, distanceMeters: Double, origin: GeoCoordinate) -> GeoCoordinate
    {
        if self.showDebugInformation {
            NSLog("=> INFO: LocationWithBearing: Origin(lat:%f,lon:%f)", origin.latitude, origin.longitude)
        }
        
        let distRadians: Double = distanceMeters / GlobalConstants.AKEarthRadius
        
        let lat1: Double = origin.latitude * (Double.pi / 180)
        let lon1: Double = origin.longitude * (Double.pi / 180)
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        let pointZ = GeoCoordinate(latitude: lat2 * (180 / Double.pi), longitude: lon2 * (180 / Double.pi))
        if self.showDebugInformation {
            NSLog("=> INFO: LocationWithBearing: Point.Z(lat:%f,lon:%f)", pointZ.latitude, pointZ.longitude)
        }
        
        return pointZ
    }
    
    ///
    /// Returns the App's master file object.
    ///
    /// - Returns: The App's master file.
    ///
    func AKObtainMasterFile() -> AKMasterFile
    {
        return GlobalFunctions.instance(self.showDebugInformation).AKDelegate().masterFile
    }
    
    ///
    /// Returns the user data structure.
    ///
    /// - Returns: The user data structure.
    ///
    func AKGetUser() -> User
    {
        return GlobalFunctions.instance(self.showDebugInformation).AKObtainMasterFile().user
    }
    
    func AKPresentMessageFromError(_ errorMessage: String = "", controller: UIViewController!)
    {
        do {
            let input = errorMessage
            let regex = try NSRegularExpression(pattern: ".*\"(.*)\"", options: NSRegularExpression.Options.caseInsensitive)
            let matches = regex.matches(in: input, options: [], range: NSMakeRange(0, input.characters.count))
            
            if let match = matches.first {
                let range = match.rangeAt(1)
                if let swiftRange = AKRangeFromNSRange(range, forString: input) {
                    let msg = input.substring(with: swiftRange)
                    AKPresentTopMessage(controller, type: TSMessageNotificationType.error, message: msg)
                }
            }
        }
        catch {
            NSLog("=> Generic Error ==> %@", "\(error)")
        }
    }
    
    func AKPresentTopMessage(_ presenter: UIViewController!, type: TSMessageNotificationType, message: String!)
    {
        GlobalFunctions.instance(false).AKExecuteInMainThread {
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
        }
    }
    
    ///
    /// Executes code and measures the execution time.
    ///
    /// - Parameter title: The title of the operation.
    /// - Parameter operation: The code to be executed in a closure.
    ///
    func AKPrintTimeElapsedWhenRunningCode(title: String, operation: () -> ())
    {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        NSLog("=> INFO: TIME ELAPSED FOR \(title): %.4f seconds.", timeElapsed)
    }
    
    func AKRangeFromNSRange(_ nsRange: NSRange, forString str: String) -> Range<String.Index>?
    {
        let fromUTF16 = str.utf16.startIndex.advanced(by: nsRange.location)
        let toUTF16 = fromUTF16.advanced(by: nsRange.length)
        
        if let from = String.Index(fromUTF16, within: str), let to = String.Index(toUTF16, within: str) {
            return from ..< to
        }
        
        return nil
    }
    
    ///
    /// Create an image with the form of a square.
    ///
    /// - Parameter side:        The length of the side.
    /// - Parameter strokeColor: The color of the stroke.
    /// - Parameter strokeAlpha: The alpha factor of the stroke.
    /// - Parameter fillColor:   The color of the fill.
    /// - Parameter fillAlpha:   The alpha factor of the fill.
    ///
    /// - Returns: An image object in the form of a square.
    ///
    func AKSquareImage(_ sideLength: Double, strokeColor: UIColor, strokeAlpha: Float, fillColor: UIColor, fillAlpha: Float) -> UIImage
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
    
    ///
    /// Converts the zoom scale provided by MapKit to a
    /// standard scale.
    ///
    /// - Parameter zoomScale: The zoom value as provided by MapKit.
    /// - Parameter debug: Show debug info.
    ///
    /// - Returns: A zoom level.
    ///
    func AKZoomScaleConvert(zoomScale: MKZoomScale, debug: Bool) -> Int
    {
        let maxZoom: Int = Int(log2(MKMapSizeWorld.width / 256.0))
        if debug { NSLog("=> INFO: MAX ZOOM: %i", maxZoom) }
        let currZoom: Int = Int(log2f(Float(zoomScale)))
        if debug { NSLog("=> INFO: CURRENT ZOOM: %i", currZoom) }
        
        return max(1, maxZoom + currZoom)
    }
}
