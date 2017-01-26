import MapKit
import UIKit

/// Utility functions for the heatmap view controller.
///
/// - Author: Andreas P. Koenzen <akc@apkc.net>
/// - Copyright: 2017 APKC.net
/// - Date: Jan 24, 2017
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
                            GlobalFunctions.instance(false).AKLocationWithBearing(
                                bearing: Double(k * 30) * (M_PI / 180),
                                distanceMeters: 50000,
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
        // Add map overlay for heatmap alerts.
        controller.hmAlertsOverlayViewSubView = controller.hmAlertsOverlayViewContainer.customView
        controller.hmAlertsOverlayViewContainer.controller = controller
        controller.hmAlertsOverlayViewSubView.frame = CGRect(
            x: 0,
            y: 0,
            width: controller.view.bounds.width,
            height: controller.hmAlertsOverlayViewSubView.bounds.height
        )
        controller.hmAlertsOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        controller.hmAlertsOverlayViewSubView.clipsToBounds = true
        controller.view.addSubview(controller.hmAlertsOverlayViewSubView)
        
        // Add map overlay for heatmap actions.
        controller.hmActionsOverlayViewSubView = controller.hmActionsOverlayViewContainer.customView
        controller.hmActionsOverlayViewContainer.controller = controller
        controller.hmActionsOverlayViewSubView.frame = CGRect(
            x: 0,
            y: controller.hmAlertsOverlayViewSubView.bounds.height + 1,
            width: controller.view.bounds.width,
            height: controller.hmActionsOverlayViewSubView.bounds.height
        )
        controller.hmActionsOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        controller.hmActionsOverlayViewSubView.clipsToBounds = true
        controller.view.addSubview(controller.hmActionsOverlayViewSubView)
        
        // Add map overlay for heatmap layers.
        controller.hmLayersOverlayViewSubView = controller.hmLayersOverlayViewContainer.customView
        controller.hmLayersOverlayViewContainer.controller = controller
        controller.hmLayersOverlayViewSubView.frame = CGRect(
            x: controller.mapView.bounds.width - controller.hmLayersOverlayViewSubView.bounds.width,
            y: (controller.mapView.bounds.height / 2.0) - (controller.hmLayersOverlayViewSubView.bounds.height / 2.0),
            width: controller.hmLayersOverlayViewSubView.bounds.width,
            height: controller.hmLayersOverlayViewSubView.bounds.height
        )
        controller.hmLayersOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        controller.hmLayersOverlayViewSubView.clipsToBounds = true
        controller.mapView.addSubview(controller.hmLayersOverlayViewSubView)
        
        // Add map overlay for heatmap legend.
        controller.hmLegendOverlayViewSubView = controller.hmLegendOverlayViewContainer.customView
        controller.hmLegendOverlayViewContainer.controller = controller
        controller.hmLegendOverlayViewSubView.frame = CGRect(
            x: 0,
            y: (controller.mapView.bounds.height / 2.0) - (controller.hmLegendOverlayViewSubView.bounds.height / 2.0),
            width: controller.hmLegendOverlayViewSubView.bounds.width,
            height: controller.hmLegendOverlayViewSubView.bounds.height
        )
        controller.hmLegendOverlayViewSubView.translatesAutoresizingMaskIntoConstraints = true
        controller.hmLegendOverlayViewSubView.clipsToBounds = true
        controller.mapView.addSubview(controller.hmLegendOverlayViewSubView)
        
        // Custom L&F
        controller.hmAlertsOverlayViewSubView.backgroundColor = GlobalConstants.AKOverlaysBg
        controller.hmLegendOverlayViewSubView.backgroundColor = GlobalConstants.AKOverlaysBg
        
        GlobalFunctions.instance(false).AKAddBorderDeco(
            controller.hmAlertsOverlayViewSubView,
            color: GlobalConstants.AKDefaultViewBorderBg.cgColor,
            thickness: GlobalConstants.AKDefaultBorderThickness,
            position: CustomBorderDecorationPosition.bottom
        )
    }
    
    static func hideLegend(_ controller: AKHeatMapViewController)
    {
        controller.hmLegendOverlayViewSubView.isHidden = true
    }
    
    static func showLegend(_ controller: AKHeatMapViewController)
    {
        controller.hmLegendOverlayViewSubView.isHidden = false
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
