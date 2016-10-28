import UIKit

class AKRainOverlayRenderer: MKOverlayRenderer
{
    // MARK: Properties
    let debug = false
    let rainfallPoints: [AKRainfallPoint]
    var lastZoomScale: MKZoomScale
    
    init(overlay: MKOverlay, rainfallPoints: [AKRainfallPoint])
    {
        self.rainfallPoints = rainfallPoints
        if debug {
            NSLog("=> INIT RAINFALL POINTS STRUCTURE.")
            for point in self.rainfallPoints {
                NSLog("\t=> RI: %.2f", point.intensity)
            }
        }
        self.lastZoomScale = MKZoomScale(0.0)
        
        super.init(overlay: overlay)
    }
    
    // MARK: MKOverlayRenderer Overriding
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext)
    {
        // NSLog("=> ZOOM SCALE: %f", zoomScale)
        
        for point in self.rainfallPoints {
            // Get raindrop characteristics.
            let chars = AKGetInfoForRainfallIntensity(ri: point.intensity)
            // Increase rectangle according to zoom scale.
            // PROTOTYPE!
            let oldRect = self.rect(for: point.mapRect)
            // let newRect = oldRect.insetBy(
            //     dx: CGFloat(GlobalConstants.AKRaindropSize) / ((zoomScale - self.lastZoomScale) > 0 ? zoomScale : -zoomScale),
            //     dy: CGFloat(GlobalConstants.AKRaindropSize) / ((zoomScale - self.lastZoomScale) > 0 ? zoomScale : -zoomScale)
            // )
            
            // NSLog("=> OLD RECT: %f,%f", oldRect.size.width, oldRect.size.height)
            // NSLog("=> NEW RECT: %f,%f", newRect.size.width, newRect.size.height)
            // NSLog("\t=> DX: %f", CGFloat(GlobalConstants.AKRaindropSize) / (zoomScale - self.lastZoomScale))
            
            context.saveGState();
            context.setFillColor(chars.color.cgColor);
            context.setAlpha(CGFloat(chars.alpha))
            context.setBlendMode(CGBlendMode.color);
            context.fill(oldRect)
            context.restoreGState();
        }
        
        self.lastZoomScale = zoomScale
        
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }
}
