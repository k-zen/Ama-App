import CoreLocation
import Foundation
import MapKit
import UIKit
import UserNotifications

// MARK: Typealias
typealias JSONObject = [String : Any]
typealias JSONObjectArray = [Any]
typealias JSONObjectStringArray = [String]
typealias RainIntensity = Double
typealias Forecast = String
typealias Temperature = Double
typealias Humidity = Double
typealias WindDirection = String
typealias WindVelocity = Int
typealias WeatherState = String
typealias GeoCoordinate = CLLocationCoordinate2D
typealias Latitude = Double
typealias Longitude = Double
typealias User = AKUser
typealias Alert = AKAlert

// MARK: Aliases
let Func = GlobalFunctions.instance(GlobalConstants.AKDebug)

// MARK: Extensions
extension UIImage {
    static func fromColor(color: UIColor, frame: CGRect) -> UIImage {
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

// MARK: Structures
struct GlobalConstants {
    static let AKDebug = true
    
    // L&F
    // ### Custom Color Palette:
    static let AKBlue = Func.AKHexColor(0x007AFF)
    static let AKGray1 = Func.AKHexColor(0x1B1E1F)
    static let AKGray2 = Func.AKHexColor(0x292D2F)
    static let AKWhite = UIColor.white
    // ### Custom Color Palette:
    
    static let AKMasterFileName = "MasterFile.dat"
    static let AKDefaultFont = "AvenirNextCondensed-Regular"
    static let AKSecondaryFont = "AvenirNextCondensed-DemiBold"
    static let AKDefaultBg = GlobalConstants.AKGray1
    static let AKDefaultFg = GlobalConstants.AKWhite
    static let AKTabBarBg = GlobalConstants.AKDefaultBg
    static let AKTabBarTintNormal = GlobalConstants.AKDefaultFg
    static let AKTabBarTintSelected = GlobalConstants.AKBlue
    static let AKDefaultViewBorderBg = GlobalConstants.AKBlue
    static let AKEnabledButtonBg = GlobalConstants.AKBlue
    static let AKEnabledButtonFg = GlobalConstants.AKWhite
    static let AKDisabledButtonBg = Func.AKHexColor(0xA9A9A6) // Exception!!!
    static let AKDisabledButtonFg = GlobalConstants.AKWhite
    static let AKTableHeaderCellBg = GlobalConstants.AKGray2
    static let AKTableHeaderCellBorderBg = GlobalConstants.AKBlue
    static let AKTableCellBg = GlobalConstants.AKDefaultBg
    static let AKTableCellBorderBg = GlobalConstants.AKBlue
    static let AKNavBarFontSize: CGFloat = 20.0
    static let AKTabBarFontSize: CGFloat = 20.0
    static let AKViewCornerRadius: CGFloat = 4.0
    static let AKButtonCornerRadius: CGFloat = 2.0
    static let AKDefaultBorderThickness = 2.0
    static let AKDefaultTransitionStyle = UIModalTransitionStyle.crossDissolve
    static let AKUserAnnotationBg = GlobalConstants.AKBlue
    static let AKAlertAnnotationBg = Func.AKHexColor(0xFF364D) // Exception!!!
    static let AKUserOverlayBg = GlobalConstants.AKGray1
    static let AKLocationUpdateInterval = 30
    static let AKLocationUpdateNotificationName = "AKLocationUpdate"
    static let AKRadarLatitude = -25.333079999999999
    static let AKRadarLongitude = -57.523449999999997
    static let AKLatitudeDegreeInKilometers = 111.0 // http://gis.stackexchange.com/questions/142326/calculating-longitude-length-in-miles
    static let AKPYBoundsPointA = GeoCoordinate(latitude: -19.207429, longitude: -63.413086)
    static let AKPYBoundsPointB = GeoCoordinate(latitude: -27.722436, longitude: -52.778320)
    static let AKRaindropSize: Double = 100.0 // This is the square side length in meters.
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
    static let AKMaxAlertNameLength = 20
    static let AKMinAlertNameLength = 3
    static let AKDefaultZoomLevel = ZoomLevel.L06
    static let AKDIMOverlayAlpha = 0.60
    static let AKAmaServerAddress = "http://190.128.205.74:8102"
    static let AKDMHServerAddress = "http://190.128.205.78:8080/api/get_all/183"
    static let AKCloseKeyboardToolbarHeight: CGFloat = 30
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
    /// 0.6Km
    case L11 = 0.6
    /// 0.4Km
    case L12 = 0.4
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

enum MessageType: String {
    case info = "Información"
    case warning = "Advertencia"
    case error = "Error"
}

enum ExecutionMode {
    case syncMain
    case asyncMain
    case syncBackground
    case asyncBackground
}

// MARK: Global Functions
class GlobalFunctions {
    private var showDebugInformation = false
    
    static func instance(_ showDebugInformation: Bool) -> GlobalFunctions {
        let instance = GlobalFunctions()
        instance.showDebugInformation = showDebugInformation
        
        return instance
    }
    
    func AKAddBlurView(view: UIView, effect: UIBlurEffectStyle, addClearColorBgToView: Bool = false) {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: effect))
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.translatesAutoresizingMaskIntoConstraints = true
        blurView.frame = view.frame
        
        if addClearColorBgToView {
            view.backgroundColor = UIColor.clear
        }
        
        view.insertSubview(blurView, at: 0)
    }
    
    func AKAddBorderDeco(_ component: UIView, color: CGColor, thickness: Double, position: CustomBorderDecorationPosition) {
        let border = CALayer()
        border.backgroundColor = color
        switch position {
        case .top:
            border.frame = CGRect(x: 0.0, y: 0.0, width: component.frame.width, height: CGFloat(thickness))
            break
        case .right:
            border.frame = CGRect(x: (component.frame.width - CGFloat(thickness)), y: 0.0, width: CGFloat(thickness), height: component.frame.height)
            break
        case .bottom:
            border.frame = CGRect(x: 0.0, y: (component.frame.height - CGFloat(thickness)), width: component.frame.width, height: CGFloat(thickness))
            break
        case .left:
            border.frame = CGRect(x: 0.0, y: 0.0, width: CGFloat(thickness), height: component.frame.height)
            break
        }
        
        component.layer.addSublayer(border)
        component.layoutIfNeeded()
    }
    
    func AKAddDoneButtonKeyboard(_ textControl: AnyObject, controller: AKCustomViewController) {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.frame = CGRect(x: 0.0, y: 0.0, width: textControl.frame.width, height: GlobalConstants.AKCloseKeyboardToolbarHeight)
        keyboardToolbar.barStyle = .blackTranslucent
        keyboardToolbar.isTranslucent = true
        keyboardToolbar.sizeToFit()
        keyboardToolbar.clipsToBounds = true
        keyboardToolbar.alpha = 0.75
        
        let container = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 120.0, height: GlobalConstants.AKCloseKeyboardToolbarHeight))
        
        let button = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 120.0, height: GlobalConstants.AKCloseKeyboardToolbarHeight))
        button.setTitle("Cerrar Teclado", for: .normal)
        button.setTitleColor(GlobalConstants.AKTabBarTintSelected, for: .normal)
        button.titleLabel?.font = UIFont(name: GlobalConstants.AKSecondaryFont, size: 16.0)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = GlobalConstants.AKButtonCornerRadius
        button.addTarget(controller, action: #selector(AKCustomViewController.tap(_:)), for: .touchUpInside)
        
        container.addSubview(button)
        
        keyboardToolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(customView: container)]
        
        if textControl is UITextField {
            let textControlTmp = textControl as! UITextField
            textControlTmp.inputAccessoryView = keyboardToolbar
        }
        else if textControl is UITextView {
            let textControlTmp = textControl as! UITextView
            textControlTmp.inputAccessoryView = keyboardToolbar
        }
    }
    
    func AKAppBuild() -> String {
        if let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return b
        }
        else {
            return "0"
        }
    }
    
    func AKAppVersion() -> String {
        if let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return v
        }
        else {
            return "0"
        }
    }
    
    func AKCenterMapOnLocation(mapView: MKMapView, location: GeoCoordinate, zoomLevel: ZoomLevel, setRegion: Bool = true) {
        Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
            let span = MKCoordinateSpanMake(
                zoomLevel.rawValue / GlobalConstants.AKLatitudeDegreeInKilometers,
                zoomLevel.rawValue / GlobalConstants.AKLatitudeDegreeInKilometers
            )
            
            mapView.setCenter(location, animated: true)
            if setRegion {
                mapView.setRegion(
                    MKCoordinateRegion(
                        center: location,
                        span: span
                    ),
                    animated: true
                )
            }
        }
    }
    
    func AKCenterScreenCoordinate(container: UIView, width: CGFloat, height: CGFloat) -> CGPoint {
        let offsetX: CGFloat = (container.frame.width / 2.0) - (width / 2.0)
        let offsetY: CGFloat = (container.frame.height / 2.0) - (height / 2.0)
        
        return container.convert(CGPoint(x: offsetX, y: offsetY), to: container)
    }
    
    func AKChangeComponentHeight(component: UIView, newHeight: CGFloat) {
        component.frame = CGRect(origin: component.frame.origin, size: CGSize(width: component.frame.width, height: newHeight))
        component.layoutIfNeeded()
    }
    
    func AKCircleImageWithRadius(_ radius: Int, strokeColor: UIColor, strokeAlpha: Float, fillColor: UIColor, fillAlpha: Float, lineWidth: CGFloat = 1) -> UIImage {
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
    
    func AKDelegate() -> AKAppDelegate { return UIApplication.shared.delegate as! AKAppDelegate }
    
    func AKExecute(mode: ExecutionMode, timeDelay: Double, code: @escaping (Void) -> Void) {
        switch mode {
        case .syncBackground:
            DispatchQueue
                .global(qos: .background)
                .sync(execute: code)
            break
        case .asyncBackground:
            DispatchQueue
                .global(qos: .background)
                .asyncAfter(deadline: DispatchTime.now() + Double(Int64(timeDelay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: code)
            break
        case .syncMain:
            DispatchQueue
                .main
                .sync(execute: code)
            break
        case .asyncMain:
            DispatchQueue
                .main
                .asyncAfter(deadline: DispatchTime.now() + Double(Int64(timeDelay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: code)
            break
        }
    }
    
    func AKGetInfoForRainfallIntensity(ri: RainIntensity) -> AKRainfallIntensityColor {
        switch ri {
        case 0.0 ..< 25.0:
            return AKRainfallIntensityColor(color: Func.AKHexColor(HeatMapColor.C01.rawValue), alpha: 0.50)
        case 25.0 ..< 50.0:
            return AKRainfallIntensityColor(color: Func.AKHexColor(HeatMapColor.C02.rawValue), alpha: 0.50)
        case 50.0 ..< 75.0:
            return AKRainfallIntensityColor(color: Func.AKHexColor(HeatMapColor.C03.rawValue), alpha: 0.50)
        case 75.0 ..< 100.0:
            return AKRainfallIntensityColor(color: Func.AKHexColor(HeatMapColor.C04.rawValue), alpha: 0.50)
        case 100.0 ..< 125.0:
            return AKRainfallIntensityColor(color: Func.AKHexColor(HeatMapColor.C05.rawValue), alpha: 0.50)
        case 125.0 ..< 150.0:
            return AKRainfallIntensityColor(color: Func.AKHexColor(HeatMapColor.C06.rawValue), alpha: 0.50)
        case 150.0 ..< 175.0:
            return AKRainfallIntensityColor(color: Func.AKHexColor(HeatMapColor.C07.rawValue), alpha: 0.50)
        case 175.0 ..< 200.0:
            return AKRainfallIntensityColor(color: Func.AKHexColor(HeatMapColor.C08.rawValue), alpha: 0.50)
        case 200.0 ..< 225.0:
            return AKRainfallIntensityColor(color: Func.AKHexColor(HeatMapColor.C09.rawValue), alpha: 0.50)
        case 225.0 ..< RainIntensity.greatestFiniteMagnitude:
            return AKRainfallIntensityColor(color: Func.AKHexColor(HeatMapColor.C10.rawValue), alpha: 0.50)
        default:
            return AKRainfallIntensityColor(color: UIColor.clear, alpha: 0.0)
        }
    }
    
    func AKGetNotificationCenter() -> UNUserNotificationCenter { return Func.AKDelegate().notificationCenter }
    
    func AKGetUser() -> User { return Func.AKObtainMasterFile().user }
    
    func AKHexColor(_ hex: UInt) -> UIColor {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat((hex) & 0xFF) / 255.0
        
        return UIColor.init(red: red, green: green, blue: blue, alpha: 1)
    }
    
    func AKLocationWithBearing(bearing: Double, distanceMeters: Double, origin: GeoCoordinate) -> GeoCoordinate {
        let distRadians = distanceMeters / GlobalConstants.AKEarthRadius
        
        let lat1 = origin.latitude * (Double.pi / 180)
        let lon1 = origin.longitude * (Double.pi / 180)
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        let pointZ = GeoCoordinate(latitude: lat2 * (180 / Double.pi), longitude: lon2 * (180 / Double.pi))
        
        return pointZ
    }
    
    func AKObtainMasterFile() -> AKMasterFile { return Func.AKDelegate().masterFile }
    
    func AKPresentMessageFromError(controller: AKCustomViewController, message: String!) {
        do {
            if let input = message {
                let regex = try NSRegularExpression(pattern: ".*\"(.*)\"", options: NSRegularExpression.Options.caseInsensitive)
                let matches = regex.matches(in: input, options: [], range: NSMakeRange(0, input.characters.count))
                
                if let match = matches.first {
                    let range = match.rangeAt(1)
                    if let swiftRange = AKRangeFromNSRange(range, forString: input) {
                        let msg = input.substring(with: swiftRange)
                        AKPresentMessage(controller: controller, type: .error, message: msg)
                    }
                }
            }
        }
        catch {
            NSLog("=> ERROR: \(error)")
        }
    }
    
    func AKPresentMessage(controller: AKCustomViewController, type: MessageType, message: String!) {
        Func.AKExecute(mode: .asyncMain, timeDelay: 0.0) { (Void) -> Void in
            controller.showMessage(
                origin: CGPoint.zero,
                type: type,
                message: message,
                animate: true,
                completionTask: nil
            )
        }
    }
    
    func AKPrintTimeElapsedWhenRunningCode(title: String, operation: (Void) -> (Void)) {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        NSLog("=> INFO: TIME ELAPSED FOR \(title): %.4f seconds.", timeElapsed)
    }
    
    func AKRangeFromNSRange(_ nsRange: NSRange, forString str: String) -> Range<String.Index>? {
        let fromUTF16 = str.utf16.startIndex.advanced(by: nsRange.location)
        let toUTF16 = fromUTF16.advanced(by: nsRange.length)
        
        if let from = String.Index(fromUTF16, within: str), let to = String.Index(toUTF16, within: str) {
            return from ..< to
        }
        
        return nil
    }
    
    func AKZoomScaleConvert(zoomScale: MKZoomScale, debug: Bool) -> Int {
        let maxZoom: Int = Int(log2(MKMapSizeWorld.width / 256.0))
        if debug { NSLog("=> INFO: MAX ZOOM: %i", maxZoom) }
        let currZoom: Int = Int(log2f(Float(zoomScale)))
        if debug { NSLog("=> INFO: CURRENT ZOOM: %i", currZoom) }
        
        return max(1, maxZoom + currZoom)
    }
}
