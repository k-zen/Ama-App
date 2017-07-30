import MapKit
import UIKit

class AKDBZOverlayRenderer: MKOverlayRenderer {
    // MARK: Properties
    let debug = false
    let dBZPoints: [AKDBZPoint]
    var lastZoomScale: MKZoomScale
    
    init(overlay: MKOverlay, dBZPoints: [AKDBZPoint]) {
        self.dBZPoints = dBZPoints
        self.lastZoomScale = MKZoomScale(0.0)
        
        super.init(overlay: overlay)
    }
    
    // MARK: MKOverlayRenderer Overriding
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let tileRect = self.rect(for: mapRect)
        let zoomLevel = Func.AKZoomScaleConvert(zoomScale: zoomScale, debug: false)
        
        // Paint Map's grid.
        context.setStrokeColor(Func.AKHexColor(0x222222).cgColor)
        context.stroke(tileRect, width: CGFloat(1.5 / zoomScale))
        
        // Fill map rectangle tiles.
        if self.debug {
            let reducedTile = MKMapRectInset(mapRect, GlobalConstants.AKMapTileTolerance.x, GlobalConstants.AKMapTileTolerance.y)
            context.setFillColor(UIColor.green.cgColor)
            context.setAlpha(0.25)
            context.fill(self.rect(for: reducedTile))
        }
        
        if self.debug {
            NSLog("=> INFO: ZOOM (SCALE, LEVEL): %f,%i", zoomScale, zoomLevel)
            NSLog("=> INFO: TILE WIDTH: (w:%f,h:%f)", tileRect.size.width, tileRect.size.height)
        }
        
        for point in self.dBZPoints {
            // Draw only the dBZ points that are inside the map rectangle with tolerance.
            let tileTolerance = MKMapRectInset(mapRect, -GlobalConstants.AKMapTileTolerance.x, -GlobalConstants.AKMapTileTolerance.y)
            if MKMapRectContainsRect(tileTolerance, point.mapRect) {
                let chars = Func.AKGetInfoForDBZIntensity(ri: point.intensity)
                let dBZPointRect = self.rect(for: point.mapRect)
                
                context.setFillColor(chars.color.cgColor)
                context.setAlpha(CGFloat(chars.alpha))
                context.setBlendMode(CGBlendMode.normal)
                context.fillEllipse(in: dBZPointRect)
            }
        }
        
        self.lastZoomScale = zoomScale
    }
}
