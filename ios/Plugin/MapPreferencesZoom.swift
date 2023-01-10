import Capacitor
import GoogleMaps

class MapPreferencesZoom {
    public static let MIN_ZOOM_KEY: String! = "minZoom"
    public static let MAX_ZOOM_KEY: String! = "maxZoom"
    
    var minZoom = 8
    var maxZoom = 22
    
    func updateFromJSObject(object: JSObject) {
        if object[MapPreferencesZoom.MIN_ZOOM_KEY] != nil {
            if let minZoomUpdate = object[MapPreferencesZoom.MIN_ZOOM_KEY] as? Int {
                minZoom = minZoomUpdate
            }
        }
        
        if object[MapPreferencesZoom.MAX_ZOOM_KEY] != nil {
            if let maxZoomUpdate = object[MapPreferencesZoom.MAX_ZOOM_KEY] as? Int {
                maxZoom = maxZoomUpdate
            }
        }
    }
    
    func getJSObject(_ mapView: GMSMapView) -> JSObject {
        return [MapPreferencesZoom.MIN_ZOOM_KEY: mapView.minZoom, MapPreferencesZoom.MAX_ZOOM_KEY: mapView.maxZoom]
    }
}
