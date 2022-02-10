import UIKit
import Capacitor
import GoogleMaps

class CustomWKWebView: WKWebView {
    var customMapViews = [String : CustomMapView]();
    var mapId: String?
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let mapId: String = self.mapId!

        let customMapView = self.customMapViews[mapId];
        
        let convertedPoint = self.convert(point, to: customMapView!.GMapView)
        let mapView = customMapView!.GMapView.hitTest(convertedPoint, with: event)

        if scrollView.layer.pixelColorAtPoint(point: convertedPoint) == true{
            return mapView
        }
        return super.hitTest(point, with: event)
    }
}

class CustomMapViewController: CAPBridgeViewController {
    open override func webView(with frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        return CustomWKWebView(frame: frame, configuration: configuration)
    }
}
