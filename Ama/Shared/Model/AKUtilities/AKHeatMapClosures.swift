import MapKit
import UIKit

class AKHeatMapClosures: NSObject
{
    static let loadRainMap: (_ controller: AKHeatMapViewController, _ progress: UIProgressView?, _ caller: UIButton) -> Void = { (controller, progress, caller) -> Void in
        Func.AKPrintTimeElapsedWhenRunningCode(title: "Load_HeatMap", operation: { Void -> Void in
            if !controller.layersOverlay.layersState {
                return
            }
            
            caller.isEnabled = false
            UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKDisabledButtonBg })
            
            progress?.setProgress(0.25, animated: true)
            
            AKHeatMapUtilityFunctions.clearMap(controller)
            AKHeatMapUtilityFunctions.addDefaultMapOverlays(controller)
            
            Func.AKDelay(2.0, task: { Void -> Void in
                Func.AKCenterMapOnLocation(
                    mapView: controller.mapView,
                    location: Func.AKDelegate().currentPosition ?? GlobalConstants.AKRadarOrigin,
                    zoomLevel: GlobalConstants.AKDefaultZoomLevel
                )
            })
            
            let rainfallPoints = NSMutableArray()
            let requestBody = ""
            let url = String(format: "%@/ama/ultimodato", GlobalConstants.AKAmaServerAddress)
            let completionTask: (Any) -> Void = { (json) -> Void in
                Func.AKExecuteInMainThread(mode: .async) { (Void) -> Void in
                    progress?.setProgress(0.50, animated: true)
                }
                
                if let dictionary = json as? JSONObject {
                    if let array = dictionary["arrayDatos"] as? JSONObjectArray {
                        for element in array {
                            if let e = element as? JSONObject {
                                let intensity = e["intensidad"] as? RainIntensity ?? GlobalConstants.AKInvalidIntensity
                                let coordinates = e["coordenadas"] as? JSONObjectStringArray ?? []
                                for coordinate in coordinates {
                                    let lat = CLLocationDegrees(coordinate.components(separatedBy: ":")[0])!
                                    let lon = CLLocationDegrees(coordinate.components(separatedBy: ":")[1])!
                                    let location = GeoCoordinate(latitude: lat, longitude: lon)
                                    
                                    rainfallPoints.add(AKRainfallPoint(center: location, intensity: intensity))
                                }
                                
                                Func.AKExecuteInMainThread(mode: .async) { (Void) -> Void in
                                    progress?.setProgress(0.75, animated: true)
                                }
                            }
                        }
                        
                        Func.AKExecuteInMainThread(mode: .async) { (Void) -> Void in
                            controller.mapView.add(AKRainOverlay(rainfallPoints: rainfallPoints), level: MKOverlayLevel.aboveRoads)
                            progress?.setProgress(1.0, animated: true)
                        }
                    }
                }
                
                Func.AKExecuteInMainThread(mode: .async) { (Void) -> Void in
                    controller.locationObserver()
                }
                
                Func.AKDelay(2.0, task: { Void -> Void in
                    progress?.setProgress(0.0, animated: false)
                    caller.isEnabled = true
                    UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                })
            }
            let failureTask: (Int, String) -> Void = { (code, message) -> Void in
                switch code {
                case ErrorCodes.ConnectionToBackEndError.rawValue:
                    Func.AKPresentMessage(
                        controller: controller,
                        type: .error,
                        message: message
                    )
                    break
                case ErrorCodes.InvalidMIMEType.rawValue:
                    Func.AKPresentMessage(
                        controller: controller,
                        type: .error,
                        message: "El servicio devolvió una respuesta inválida. Reportando..."
                    )
                    break
                case ErrorCodes.JSONProcessingError.rawValue:
                    Func.AKPresentMessage(
                        controller: controller,
                        type: .error,
                        message: "Error procesando respuesta. Reportando..."
                    )
                    break
                default:
                    Func.AKPresentMessage(
                        controller: controller,
                        type: .error,
                        message: String(format: "%d: Error genérico.", code)
                    )
                    break
                }
                
                Func.AKDelay(2.0, task: { Void -> Void in
                    progress?.setProgress(0.0, animated: false)
                    caller.isEnabled = true
                    UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                })
            }
            
            Func.AKDelay(0.0, isMain: false, task: { Void -> Void in
                AKWSUtils.makeRESTRequest(
                    controller: controller,
                    endpoint: url,
                    httpMethod: "GET",
                    headerValues: [ "Content-Type" : "application/json" ],
                    bodyValue: requestBody,
                    completionTask: { (jsonDocument) -> Void in completionTask(jsonDocument) },
                    failureTask: { (code, message) -> Void in failureTask(code, message!) }
                )
            })
        })
    }
    
    static let updateWeatherStatus: (AKHeatMapViewController) -> Void = { (controller) -> Void in
        Func.AKDelay(0.0, isMain: false, task: {
            // TODO: Add support for querying temperature via Apple here.
        })
        
        if Func.AKDelegate().applicationActive {
            UIView.transition(
                with: controller.topOverlay.alertValue,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: {
                    // TODO: Add function here to detect the state of weather and issue a label in 3 possible categories.
                    controller.topOverlay.alertValue.text = "Lluvioso ☂".uppercased() },
                completion: nil
            )
        }
        else {
            UIView.transition(
                with: controller.topOverlay.alertValue,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: {
                    controller.topOverlay.alertValue.text = "Deshabilitado".uppercased() },
                completion: nil
            )
        }
        
        if GlobalConstants.AKDebug {
            NSLog("=> INFO: NUMBER OF OVERLAYS => %d", controller.mapView.overlays.count)
        }
        
        Func.AKDelay(2.0, task: {
            CLGeocoder().reverseGeocodeLocation(
                CLLocation(
                    latitude: Func.AKDelegate().currentPosition?.latitude ?? kCLLocationCoordinate2DInvalid.latitude,
                    longitude: Func.AKDelegate().currentPosition?.longitude ?? kCLLocationCoordinate2DInvalid.longitude
                ),
                completionHandler: { (placemarks, error) in
                    if error == nil {
                        if let p = placemarks {
                            if p.count > 0 {
                                UIView.transition(
                                    with: controller.topOverlay.location,
                                    duration: 1.00,
                                    options: [UIViewAnimationOptions.transitionCrossDissolve],
                                    animations: {
                                        if let lines: Array<String> = p[0].addressDictionary?["FormattedAddressLines"] as? Array<String> {
                                            let placeString = lines.joined(separator: ", ")
                                            controller.topOverlay.location.text = String(
                                                format: "%@", placeString
                                            )
                                        }
                                        else {
                                            controller.topOverlay.location.text = String(
                                                format: "%@, %@", p[0].locality ?? "---", p[0].country ?? "---"
                                            )
                                        } },
                                    completion: nil
                                )
                            }
                        }
                    } }
            )
        })
    }
}
