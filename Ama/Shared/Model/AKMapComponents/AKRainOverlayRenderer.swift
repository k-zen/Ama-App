import MapKit
import UIKit

class AKRainOverlayRenderer: MKOverlayRenderer {
    // MARK: Properties
    let debug = false
    let rainfallPoints: [AKRainfallPoint]
    var lastZoomScale: MKZoomScale
    
    init(overlay: MKOverlay, rainfallPoints: [AKRainfallPoint]) {
        self.rainfallPoints = rainfallPoints
        self.lastZoomScale = MKZoomScale(0.0)
        
        super.init(overlay: overlay)
    }
    
    // MARK: MKOverlayRenderer Overriding
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let tileRect = self.rect(for: mapRect)
        let zoomLevel = Func.AKZoomScaleConvert(zoomScale: zoomScale, debug: false)
        
        // Mark map rectangle tiles.
        if self.debug {
            context.setStrokeColor(Func.AKHexColor(0x222222).cgColor);
            context.stroke(tileRect, width: CGFloat(5000 / zoomLevel))
            
            let reducedTile = MKMapRectInset(mapRect, GlobalConstants.AKMapTileTolerance.x, GlobalConstants.AKMapTileTolerance.y)
            context.setFillColor(UIColor.green.cgColor)
            context.setAlpha(0.25)
            context.fill(self.rect(for: reducedTile))
        }
        
        if self.debug {
            NSLog("=> INFO: ZOOM (SCALE, LEVEL): %f,%i", zoomScale, zoomLevel)
            NSLog("=> INFO: TILE WIDTH: (w:%f,h:%f)", tileRect.size.width, tileRect.size.height)
        }
        
        for point in self.rainfallPoints {
            // Draw only the rainfall points that are inside the map rectangle with tolerance.
            let tileTolerance = MKMapRectInset(mapRect, -GlobalConstants.AKMapTileTolerance.x, -GlobalConstants.AKMapTileTolerance.y)
            if MKMapRectContainsRect(tileTolerance, point.mapRect) {
                // Get raindrop characteristics.
                let chars = Func.AKGetInfoForRainfallIntensity(ri: point.intensity)
                let raindropPointRect = self.rect(for: point.mapRect)
                
                context.setFillColor(chars.color.cgColor)
                context.setAlpha(CGFloat(chars.alpha))
                context.setBlendMode(CGBlendMode.normal)
                context.fill(raindropPointRect)
                // context.setStrokeColor(chars.color.cgColor)
                // context.setAlpha(CGFloat(1.0))
                // context.setLineWidth(100.0)
                // context.setBlendMode(CGBlendMode.colorDodge)
                // context.stroke(raindropPointRect)
            }
        }
        
        self.lastZoomScale = zoomScale
    }
}
