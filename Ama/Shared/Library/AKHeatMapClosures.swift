import MapKit
import TSMessages
import UIKit

/// Closures for the heatmap view controller.
///
/// - Author: Andreas P. Koenzen <akc@apkc.net>
/// - Copyright: 2017 APKC.net
/// - Date: Jan 24, 2017
class AKHeatMapClosures: NSObject
{
    /// This closure handles the display and building of the rainmap. It contains all necessary code including
    /// the calls to the backend.
    ///
    /// - Parameter controller: The controller, from where this closure will be called.
    /// - Parameter progress: The progress view.
    /// - Parameter caller: The button used to call this closure.
    static let loadRainMap: (_ controller: AKHeatMapViewController, _ progress: UIProgressView?, _ caller: UIButton) -> Void = { (controller, progress, caller) -> Void in
        // Measure the performance of this closure.
        GlobalFunctions.instance(false).AKPrintTimeElapsedWhenRunningCode(title: "Load_HeatMap", operation: { Void -> Void in
            // If the rainmap overlay is disabled then return here and do nothing.
            if !controller.hmLayersOverlayViewContainer.layersState {
                return
            }
            
            // Disable the caller button, in this case the enable/disable layers button located
            // in the center-right part of the screen. Animate the change.
            caller.isEnabled = false
            UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKDisabledButtonBg })
            
            // Set the progress at 25%.
            progress?.setProgress(0.25, animated: true)
            
            // Clear all overlays, then add the default overlays (DIM and Radar).
            AKHeatMapUtilityFunctions.clearMap(controller)
            AKHeatMapUtilityFunctions.addDefaultMapOverlays(controller)
            
            // Adjust zoom level and center map around the radar.
            GlobalFunctions.instance(false).AKCenterMapOnLocation(
                mapView: controller.mapView,
                location: GlobalConstants.AKRadarOrigin,
                zoomLevel: ZoomLevel.L03
            )
            
            // Configure the request to the backend.
            let rainfallPoints = NSMutableArray()
            let requestBody = ""
            let url = String(format: "%@/ama/ultimodato", "http://devel.apkc.net:9001")
            // This closure will be executed if success.
            let completionTask: (Any) -> Void = { (json) -> Void in
                // Set the progress at 50%.
                GlobalFunctions.instance(false).AKExecuteInMainThread {
                    progress?.setProgress(0.50, animated: true)
                }
                
                // Process the results.
                if let dictionary = json as? [String : Any] {
                    if let array = dictionary["arrayDatos"] as? [Any] {
                        for element in array {
                            if let e = element as? [String : Any] {
                                let intensity = e["intensidad"] as? Int ?? GlobalConstants.AKInvalidIntensity
                                let coordinates = e["coordenadas"] as? [String] ?? []
                                for coordinate in coordinates {
                                    let lat = CLLocationDegrees(Double(coordinate.components(separatedBy: ":")[0])!)
                                    let lon = CLLocationDegrees(Double(coordinate.components(separatedBy: ":")[1])!)
                                    let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                    
                                    rainfallPoints.add(AKRainfallPoint(center: location, intensity: intensity))
                                }
                                
                                // Set the progress at 75%.
                                GlobalFunctions.instance(false).AKExecuteInMainThread {
                                    progress?.setProgress(0.75, animated: true)
                                }
                            }
                        }
                        
                        // Set the progress at 100% and add the rainmap overlay.
                        GlobalFunctions.instance(false).AKExecuteInMainThread {
                            controller.mapView.add(AKRainOverlay(rainfallPoints: rainfallPoints), level: MKOverlayLevel.aboveRoads)
                            progress?.setProgress(1.0, animated: true)
                        }
                    }
                }
                
                // Call locationUpdated to set the user's pin and update the user's status.
                GlobalFunctions.instance(false).AKExecuteInMainThread {
                    controller.locationObserver()
                }
                
                // Reset everything with a 2 second delay.
                GlobalFunctions.instance(false).AKDelay(2.0, task: { Void -> Void in
                    progress?.setProgress(0.0, animated: false)
                    caller.isEnabled = true
                    UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                })
            }
            // This closure will be executed if failure.
            let failureTask: (Int, String) -> Void = { (code, message) -> Void in
                switch code {
                case ErrorCodes.ConnectionToBackEndError.rawValue:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: message
                    )
                    break
                case ErrorCodes.InvalidMIMEType.rawValue:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: "El servicio devolvió una respuesta inválida. Reportando..."
                    )
                    break
                case ErrorCodes.JSONProcessingError.rawValue:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: "Error procesando respuesta. Reportando..."
                    )
                    break
                default:
                    GlobalFunctions.instance(false).AKPresentTopMessage(
                        controller,
                        type: TSMessageNotificationType.error,
                        message: String(format: "%d: Error genérico.", code)
                    )
                    break
                }
                
                // Reset everything with a 2 second delay, even if failure.
                GlobalFunctions.instance(false).AKDelay(2.0, task: { Void -> Void in
                    progress?.setProgress(0.0, animated: false)
                    caller.isEnabled = true
                    UIView.animate(withDuration: 1.0, animations: { () -> Void in caller.backgroundColor = GlobalConstants.AKEnabledButtonBg })
                })
            }
            
            // Make the request.
            GlobalFunctions.instance(false).AKDelay(0.0, isMain: false, task: { Void -> Void in
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
    
    /// This closure handles the update of the alert's view overlay.
    ///
    /// - Parameter controller: The controller, from where this closure will be called.
    static let updateWeatherStatus: (AKHeatMapViewController) -> Void = { (controller) -> Void in
        // Set the state of the alert or if it's disabled using animation.
        if GlobalFunctions.instance(false).AKDelegate().applicationActive {
            UIView.transition(
                with: controller.hmAlertsOverlayViewContainer.alertValue,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: {
                    // TODO: Add function here to detect the state of weather and issue a label in 3 possible categories.
                    controller.hmAlertsOverlayViewContainer.alertValue.text = "Lluvioso ☂".uppercased() },
                completion: nil
            )
        }
        else {
            UIView.transition(
                with: controller.hmAlertsOverlayViewContainer.alertValue,
                duration: 1.0,
                options: [UIViewAnimationOptions.transitionCrossDissolve],
                animations: {
                    controller.hmAlertsOverlayViewContainer.alertValue.text = "Deshabilitado".uppercased() },
                completion: nil
            )
        }
        
        if GlobalConstants.AKDebug {
            NSLog("=> INFO: NUMBER OF OVERLAYS => %d", controller.mapView.overlays.count)
        }
        
        // Using Apple's reverse geocoding function find the city and country the user is in
        // and animate the text bellow the waether's alert.
        GlobalFunctions.instance(false).AKDelay(2.0, task: {
            CLGeocoder().reverseGeocodeLocation(
                CLLocation(
                    latitude: GlobalFunctions.instance(false).AKDelegate().currentPosition.latitude,
                    longitude: GlobalFunctions.instance(false).AKDelegate().currentPosition.longitude
                ),
                completionHandler: { (placemarks, error) in
                    if error == nil {
                        if let p = placemarks {
                            if p.count > 0 {
                                UIView.transition(
                                    with: controller.hmAlertsOverlayViewContainer.location,
                                    duration: 1.00,
                                    options: [UIViewAnimationOptions.transitionCrossDissolve],
                                    animations: {
                                        if let lines: Array<String> = p[0].addressDictionary?["FormattedAddressLines"] as? Array<String> {
                                            let placeString = lines.joined(separator: ", ")
                                            controller.hmAlertsOverlayViewContainer.location.text = String(
                                                format: "%@", placeString
                                            )
                                        }
                                        else {
                                            controller.hmAlertsOverlayViewContainer.location.text = String(
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
