import Foundation
import Capacitor
import GoogleMaps
import SDWebImage

@objc(CapacitorGoogleMaps)
public class CapacitorGoogleMaps: CustomMapViewEvents {

    var GOOGLE_MAPS_KEY: String = "";

    var customMapViews = [String : CustomMapView]();

    var customMarkers = [String : CustomMarker]();
    
    let markerHandler = MarkerHandler()

    @objc func initialize(_ call: CAPPluginCall) {

        self.GOOGLE_MAPS_KEY = call.getString("key", "")

        if self.GOOGLE_MAPS_KEY.isEmpty {
            call.reject("GOOGLE MAPS API key missing!")
            return
        }

        GMSServices.provideAPIKey(self.GOOGLE_MAPS_KEY)
        call.resolve([
            "initialized": true
        ])
    }

    @objc func createMap(_ call: CAPPluginCall) {

        DispatchQueue.main.async {
            let customMapView : CustomMapView = CustomMapView(customMapViewEvents: self)

            self.bridge?.saveCall(call)
            customMapView.savedCallbackIdForCreate = call.callbackId
            
            let boundingRect = call.getObject("boundingRect", JSObject())
            customMapView.boundingRect.updateFromJSObject(boundingRect)
            
            let mapCameraPosition = call.getObject("cameraPosition", JSObject())
            customMapView.mapCameraPosition.updateFromJSObject(mapCameraPosition)

            let preferences = call.getObject("preferences", JSObject())
            customMapView.mapPreferences.updateFromJSObject(preferences)

            self.bridge?.viewController?.view.addSubview(customMapView.view)
            self.bridge?.viewController?.view.sendSubviewToBack(customMapView.view)
            self.setupWebView()
     
            self.imageCache.image(at: self.urlHand) { image in
                self.markerHandler.clusterIcon = image
                self.markerHandler.addClusterManager(with: customMapView)
            }
            
            if self.markerHandler.shouldPresentMarkersOnCameraChange {
                customMapView.showMarkers = { [weak self] in
                    self?.showMarkers(mapId: customMapView.id)
                }
            }
            
            customMapView.GMapView.delegate = customMapView;

            self.customMapViews[customMapView.id] = customMapView
        }
    }

    @objc func updateMap(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId")!;

        DispatchQueue.main.async {
            let customMapView = self.customMapViews[mapId];

            if (customMapView != nil) {
                let preferences = call.getObject("preferences", JSObject());
                customMapView?.mapPreferences.updateFromJSObject(preferences);

                customMapView?.invalidateMap();
            } else {
                call.reject("map not found");
            }
        }

    }
    
    @objc func moveCamera(_ call: CAPPluginCall) {
        guard let mapId = call.getString("mapId") else {
            call.reject("map not found")
            return
        }

        DispatchQueue.main.async {
            guard let customMapView = self.customMapViews[mapId]  else {
                call.reject("map not found")
                return
            }
            
            let mapCameraPosition = MapCameraPosition()
            let cameraPosition = call.getObject("cameraPosition", JSObject())
            mapCameraPosition.updateFromJSObject(cameraPosition)
            
            let camera = GMSMutableCameraPosition.camera(withLatitude: mapCameraPosition.latitude,
                                                         longitude: mapCameraPosition.longitude,
                                                         zoom: customMapView.GMapView.camera.zoom)
            customMapView.GMapView.animate(to: camera)
            
            call.resolve(cameraPosition)
        }
    }

    @objc func addMarker(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId", "")

        DispatchQueue.main.async {
            guard let customMapView = self.customMapViews[mapId] else {
                call.reject("map not found")
                return
            }
            let preferences = call.getObject("preferences", JSObject())
            let marker = CustomMarker()
            marker.updateFromJSObject(preferences: preferences)
            marker.map = customMapView.GMapView
            self.customMarkers[marker.id] = marker
            if let url = call.getObject("icon")?["url"] as? String {
                self.imageCache.image(at: url) { image in
                    marker.icon = image
                    guard self.markerHandler.shouldCacheMarkers else { return }
                    self.markerHandler.addMarker(marker, mapId: mapId)
                }
            }
            call.resolve(CustomMarker.getResultForMarker(marker))
        }
    }
    
    @objc func addMarkers(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId", "")
        
        DispatchQueue.main.async {
            guard let customMapView = self.customMapViews[mapId] else {
                call.reject("map not found")
                return
            }
            
            let markers = List<JSValue>(elements: call.getArray("markers", []))
            self.addMarker(node: markers.first, mapView: customMapView)
            call.resolve()
        }
    }
    
    @objc func removeMarker(_ call: CAPPluginCall) {
        let markerId: String = call.getString("markerId", "");
        
        DispatchQueue.main.async {
            guard let customMarker = self.customMarkers[markerId] else {
                call.reject("marker not found");
                return
            }
            let mapArray = self.customMapViews.map { $0.value }
            if let markerMap = customMarker.map,
               let map = mapArray.first(where: { markerMap.isEqual($0.GMapView) }) {
                self.markerHandler.removeMarker(customMarker, mapId: map.id)
            }
            customMarker.map = nil;
            self.customMarkers[markerId] = nil;
            call.resolve();
        }
    }
    
    func showMarkers(mapId: String) {
        guard let customMap = customMapViews[mapId] else { return }
        
        if markerHandler.shouldCacheMarkers {
            markerHandler.showCachedMarkers(for: customMap)
        } else {
            let visibleMarkers: [CustomMarker] = customMarkers.map {
                let marker = $0.value
                return markerHandler.prepareForPresentation(marker: marker, map: customMap)
            }
            guard markerHandler.shouldClusterMarkers else { return }
            visibleMarkers.forEach {
                $0.map = nil
            }
            markerHandler.cluster(visibleMarkers, mapId: mapId)
        }
    }
    
    @objc
    func cluster() {
        guard let mapId = customMapViews.keys.first else { return }
        markerHandler.shouldClusterMarkers = true
        showMarkers(mapId: mapId)
    }

    @objc func didTapInfoWindow(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_INFO_WINDOW);
    }

    @objc func didCloseInfoWindow(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_CLOSE_INFO_WINDOW);
    }

    @objc func didTapMap(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_MAP);
    }

    @objc func didLongPressMap(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_LONG_PRESS_MAP);
    }

    @objc func didTapMarker(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_MARKER);
    }
    
    @objc func didTapCluster(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_CLUSTER);
        print(call)
//        guard marker is GMUCluster, markerHandler.shouldClusterMarkers else { return }
//        mapView.animate(toLocation: marker.position)
//        mapView.animate(toZoom: mapView.camera.zoom + 1)
    }

    @objc func didTapMyLocationButton(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_MY_LOCATION_BUTTON);
    }

    @objc func didTapMyLocationDot(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_MY_LOCATION_DOT);
    }
    
    @objc func cameraIdleAtPosition(_ call: CAPPluginCall) {
        print(call)
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_CAMERA_IDLE_AT_POSITION);
    }

    func setCallbackIdForEvent(call: CAPPluginCall, eventName: String) {
        call.keepAlive = true;
        let callbackId = call.callbackId;
        guard let mapId = call.getString("mapId") else { return };

        let customMapView: CustomMapView = customMapViews[mapId]!;

        let preventDefault: Bool = call.getBool("preventDefault", false);
        customMapView.setCallbackIdForEvent(callbackId: callbackId, eventName: eventName, preventDefault: preventDefault);
    }

    override func lastResultForCallbackId(callbackId: String, result: PluginCallResultData) {
        let call = bridge?.savedCall(withID: callbackId);
        call?.resolve(result);
        bridge?.releaseCall(call!);
    }

    override func resultForCallbackId(callbackId: String, result: PluginCallResultData?) {
        let call = bridge?.savedCall(withID: callbackId);
        if (result != nil) {
            call?.resolve(result!);
        } else {
            call?.resolve();
        }
    }

}

private extension CapacitorGoogleMaps {
    func addMarker(node: Node<JSValue>?,
                   mapView: CustomMapView) {
        guard let node = node else { return }
        let markerObject = node.value as? JSObject ?? JSObject();
        let preferences = markerObject["preferences"] as? JSObject ?? JSObject();
        
        let marker = CustomMarker()
        marker.updateFromJSObject(preferences: preferences)
        
        self.customMarkers[marker.id] = marker
        if let url = (markerObject["icon"] as? JSObject)?["url"] as? String {
            imageCache.image(at: url) { [weak self] image in
                guard let self = self else { return }
                marker.icon = image
                if !self.markerHandler.shouldClusterMarkers {
                    marker.map = mapView.GMapView
                }
                self.addMarker(node: node.next, mapView: mapView)
                guard self.markerHandler.shouldCacheMarkers else { return }
                self.markerHandler.addMarker(marker, mapId: mapView.id)
            }
        }
    }
    
    func setupWebView() {
        self.webView?.isOpaque = false
        self.webView?.backgroundColor = .clear
        self.webView?.scrollView.backgroundColor = .clear
        self.webView?.scrollView.isOpaque = false
    }
}

extension WKWebView {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for view in subviews {
            let convertedPoint = self.convert(point, to: view)
            guard view is GMSMapView,
                  let mapView = view.hitTest(convertedPoint, with: event),
                  scrollView.layer.pixelColorAtPoint(point: point).cgColor.alpha == 0.0
                    // Alternative condition - in case of issues with map touch, disable previous and enable next line
                    //layer.pixelColorAtPoint(point: point) == mapView.layer.pixelColorAtPoint(point: convertedPoint)
            else { continue }
            return mapView
        }
        return super.hitTest(point, with: event)
    }
}

extension CapacitorGoogleMaps: ImageCachable {
    var imageCache: ImageURLLoadable {
        SDWebImageCache.shared
    }
}
