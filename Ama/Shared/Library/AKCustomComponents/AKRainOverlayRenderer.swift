import MapKit
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
        let tileRect = self.rect(for: mapRect)
        let zoomLevel = AKZoomScaleConvert(zoomScale: zoomScale, debug: false)
        
        // Mark map rectangle tiles.
        if debug {
            context.setStrokeColor(AKHexColor(0x222222).cgColor);
            context.stroke(tileRect, width: CGFloat(1000 / zoomLevel))
        }
        
        if debug {
            NSLog("=> INFO: ZOOM (SCALE, LEVEL): %f,%i", zoomScale, zoomLevel)
            NSLog("=> INFO: MAP RECT: (x:%f,y:%f),(w:%f,h:%f)",
                  mapRect.origin.x,
                  mapRect.origin.y,
                  mapRect.size.width,
                  mapRect.size.height
            )
        }
        
        var counter: Int = 0
        for point in self.rainfallPoints {
            // Draw only the rainfall points that are inside the map rectangle.
            if MKMapRectContainsRect(mapRect, point.mapRect) {
                // Get raindrop characteristics.
                let chars = AKGetInfoForRainfallIntensity(ri: point.intensity)
                let raindropPointRect = self.rect(for: point.mapRect)
                
                if debug {
                    NSLog("=> INFO: POINT MAP RECT: (x:%f,y:%f),(w:%f,h:%f)",
                          point.mapRect.origin.x,
                          point.mapRect.origin.y,
                          point.mapRect.size.width,
                          point.mapRect.size.height
                    )
                }
                
                context.setFillColor(chars.color.cgColor);
                context.setAlpha(CGFloat(chars.alpha))
                context.setBlendMode(CGBlendMode.color);
                context.fill(raindropPointRect)
                context.setStrokeColor(chars.color.cgColor);
                context.setAlpha(CGFloat(1.0))
                context.stroke(raindropPointRect, width: CGFloat(1000 / zoomLevel))
                
                counter += 1
            }
            if debug {
                if counter > 100 { break }
            }
        }
        
        if debug {
            NSLog("=> INFO: DRAWED POINTS: %i", counter)
        }
        self.lastZoomScale = zoomScale
        
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }
}
