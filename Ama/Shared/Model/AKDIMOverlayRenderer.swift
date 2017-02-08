import MapKit
import UIKit

class AKDIMOverlayRenderer: MKOverlayRenderer
{
    init(overlay: MKOverlay, mapView: MKMapView)
    {
        super.init(overlay: overlay)
    }
    
    // MARK: MKOverlayRenderer Overriding
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext)
    {
        context.setFillColor(GlobalFunctions.instance(false).AKHexColor(0x000000).cgColor)
        context.setAlpha(CGFloat(GlobalConstants.AKDIMOverlayAlpha))
        context.fill(self.rect(for: MKMapRectWorld))
    }
}
