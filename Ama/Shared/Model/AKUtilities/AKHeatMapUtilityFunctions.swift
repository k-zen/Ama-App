import MapKit
import UIKit

class AKHeatMapUtilityFunctions: NSObject
{
    static func clearMap(_ controller: AKHeatMapViewController)
    {
        if controller.mapView.overlays.count > 0 {
            let overlaysToRemove = controller.mapView.overlays.filter({ (overlay) -> Bool in
                return true
            })
            controller.mapView.removeOverlays(overlaysToRemove)
        }
        
        if GlobalConstants.AKDebug {
            NSLog("=> INFO: NUMBER OF OVERLAYS => %d", controller.mapView.overlays.count)
        }
    }
    
    static func hideLayers(_ controller: AKHeatMapViewController)
    {
        if controller.mapView.overlays.count > 0 {
            let overlaysToRemove = controller.mapView.overlays.filter({ (overlay) -> Bool in
                if overlay.isKind(of: AKRainOverlay.self) {
                    return true
                }
                else if overlay.isKind(of: AKDIMOverlay.self) {
                    return true
                }
                else {
                    return false
                }
            })
            controller.mapView.removeOverlays(overlaysToRemove)
        }
        
        if GlobalConstants.AKDebug {
            NSLog("=> INFO: NUMBER OF OVERLAYS => %d", controller.mapView.overlays.count)
        }
    }
    
    static func addDefaultMapOverlays(_ controller: AKHeatMapViewController)
    {
        if controller.addDIMOverlay {
            controller.dimOverlay = AKDIMOverlay(mapView: controller.mapView)
            controller.mapView.add(controller.dimOverlay!, level: MKOverlayLevel.aboveRoads)
        }
        if controller.addRadarOverlay {
            for k in 1...10 {
                controller.radarOverlay = AKRadarSpanOverlay(center: GlobalConstants.AKRadarOrigin, radius: CLLocationDistance(5000 * k))
                controller.radarOverlay?.title = "Cobertura Radar"
                controller.mapView.add(controller.radarOverlay!, level: MKOverlayLevel.aboveRoads)
            }
            
            for k in 1...12 {
                controller.mapView.add(
                    AKRadarSpanLinesOverlay(
                        coordinates: [
                            GlobalConstants.AKRadarOrigin,
                            Func.AKLocationWithBearing(
                                bearing: Double(k * 30) * (Double.pi / 180.0),
                                distanceMeters: 50000.0,
                                origin: GlobalConstants.AKRadarOrigin
                            )
                        ],
                        count: 2
                    )
                )
            }
        }
    }
    
    static func addDefaultViewOverlays(_ controller: AKHeatMapViewController)
    {
        controller.layersOverlay.controller = controller
        controller.layersOverlay.setup()
        controller.layersOverlay.draw(
            container: controller.mapView,
            coordinates: CGPoint(
                x: controller.mapView.bounds.width - AKLayersOverlayView.LocalConstants.AKViewWidth,
                y: (controller.mapView.bounds.height / 2.0) - (AKLayersOverlayView.LocalConstants.AKViewHeight / 2.0)
            ),
            size: CGSize(
                width: AKLayersOverlayView.LocalConstants.AKViewWidth,
                height: AKLayersOverlayView.LocalConstants.AKViewHeight
            )
        )
        
        controller.legendOverlay.controller = controller
        controller.legendOverlay.setup()
        controller.legendOverlay.draw(
            container: controller.mapView,
            coordinates: CGPoint(
                x: 0.0,
                y: (controller.mapView.bounds.height / 2.0) - (AKLegendOverlayView.LocalConstants.AKViewHeight / 2.0)
            ),
            size: CGSize(
                width: AKLegendOverlayView.LocalConstants.AKViewWidth,
                height: AKLegendOverlayView.LocalConstants.AKViewHeight
            )
        )
        
        controller.progressOverlay.controller = controller
        controller.progressOverlay.setup()
        controller.progressOverlay.draw(
            container: controller.view,
            coordinates: CGPoint(x: 0.0, y: AKTopOverlayView.LocalConstants.AKViewHeight + 1.0),
            size: CGSize(width: controller.view.bounds.width, height: AKProgressOverlayView.LocalConstants.AKViewHeight)
        )
        
        controller.topOverlay.controller = controller
        controller.topOverlay.setup()
        controller.topOverlay.draw(
            container: controller.view,
            coordinates: CGPoint.zero,
            size: CGSize(width: controller.view.bounds.width, height: AKTopOverlayView.LocalConstants.AKViewHeight)
        )
    }
    
    static func hideLegend(_ controller: AKHeatMapViewController)
    {
        controller.legendOverlay.getView().isHidden = true
    }
    
    static func showLegend(_ controller: AKHeatMapViewController)
    {
        controller.legendOverlay.getView().isHidden = false
    }
    
    static func startRefreshTimer(_ controller: AKHeatMapViewController)
    {
        controller.rainmapObserver()
        controller.refreshTimer = Timer.scheduledTimer(
            timeInterval: 30.0,
            target: controller,
            selector: #selector(AKHeatMapViewController.rainmapObserver),
            userInfo: nil,
            repeats: true
        )
    }
    
    static func stopRefreshTimer(_ controller: AKHeatMapViewController)
    {
        if let timer = controller.refreshTimer {
            if timer.isValid {
                timer.invalidate()
            }
        }
    }
    
    static func stateRefreshTimer(_ controller: AKHeatMapViewController) -> Bool
    {
        if let timer = controller.refreshTimer {
            return timer.isValid
        }
        
        return false
    }
}
