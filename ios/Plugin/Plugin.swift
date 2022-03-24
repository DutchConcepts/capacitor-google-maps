import Foundation
import Capacitor
import GoogleMaps
import GoogleMapsUtils
import SDWebImage
import UIKit

@objc(CapacitorGoogleMaps)
public class CapacitorGoogleMaps: CustomMapViewEvents {
    var GOOGLE_MAPS_KEY: String = "";

    let markerHandler = MarkerHandler()

    var customMarkers = [String : CustomMarker]();

    var customWebView: CustomWKWebView?

    @objc func initialize(_ call: CAPPluginCall) {
        self.GOOGLE_MAPS_KEY = call.getString("key", "")

        if self.GOOGLE_MAPS_KEY.isEmpty {
            call.reject("GOOGLE MAPS API key missing!")
            return
        }
        
        GMSServices.provideAPIKey(self.GOOGLE_MAPS_KEY)

        self.customWebView = self.bridge?.webView as? CustomWKWebView

        DispatchQueue.main.async {
            // remove all custom maps views from the main view
            if let values = self.customWebView?.customMapViews.map({ $0.value }) {
                CAPLog.print("mapId \(values)")
                for mapView in values {
                    (mapView as CustomMapView).view.removeFromSuperview()
                }
            }
            // reset custom map views holder
            self.customWebView?.customMapViews = [:]
        }

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
            customMapView.mapCameraPosition.updateFromJSObject(mapCameraPosition, baseCameraPosition: nil)

            let preferences = call.getObject("preferences", JSObject())
            customMapView.mapPreferences.updateFromJSObject(preferences)

            self.customWebView?.scrollView.addSubview(customMapView.view)

            if (customMapView.GMapView == nil) {
                call.reject("Map could not be created. Did you forget to update the class in Main.storyboard? If you do not know what that is, please read the documentation.")
                return
            }

            self.customWebView?.scrollView.sendSubviewToBack(customMapView.view)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.setupWebView()
            }

            customMapView.GMapView.delegate = customMapView;
            self.customWebView?.customMapViews[customMapView.id] = customMapView
            
            if self.markerHandler.shouldClusterMarkers {
                self.markerHandler.updateClusterIcon {
                    self.markerHandler.addClusterManager(with: customMapView)
                }
            }
            
            if self.markerHandler.shouldPresentMarkersOnCameraChange {
                customMapView.showMarkers = { [weak self] in
                    self?.showMarkers(mapId: customMapView.id)
                }
            }
        }
    }
   
    func showMarkers(mapId: String) {
        guard let map = customMapViews[mapId]?.GMapView else { return }
        let camView = map.projection.visibleRegion()
        let cameraBounds = GMSCoordinateBounds(region: camView)
        let markers = markerHandler.shouldCacheMarkers ? markerHandler.cachedMarkers(for: mapId) : Array(customMarkers.values)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let visibleMarkers: [CustomMarker] = markers.filter {
                $0.map = nil
                if self.markerHandler.shouldPresentMarkersOnCameraChange {
                    return cameraBounds.contains($0.position)
                }
                return true
            }
            guard self.markerHandler.shouldClusterMarkers else {
                visibleMarkers.forEach { $0.map = map }
                return
            }
            self.markerHandler.cluster(visibleMarkers, mapId: mapId)
        }
    }
    
    @objc func updateMap(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId", "")

        DispatchQueue.main.async {
            guard let customMapView = self.customWebView?.customMapViews[mapId] else {
                call.reject("map not found")
                return
            }
            
            let preferences = call.getObject("preferences", JSObject());
            customMapView.mapPreferences.updateFromJSObject(preferences);
            
            let result = customMapView.invalidateMap()
            
            call.resolve(result)
        }
    }
    
    @objc func getMap(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId", "")

        DispatchQueue.main.async {
            guard let customMapView = self.customWebView?.customMapViews[mapId] else {
                call.reject("map not found")
                return
            }
            
            let result = customMapView.getMap()
            
            call.resolve(result)
        }
    }
    
    @objc func cluster(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId", "")
        markerHandler.shouldClusterMarkers = true
        for marker in self.customMarkers {
            marker.value.map = nil
        }
        
        if markerHandler.clusterManager(for: mapId) == nil {
            guard let map = customMapViews[mapId] else { return }
            markerHandler.addClusterManager(with: map)
        }
        
        markerHandler.updateClusterIcon { [weak self] in
            self?.showMarkers(mapId: mapId)
        }
    }
    
    @objc func updateClusterIcon() {
        self.markerHandler.updateClusterIcon(completion: nil)
    }
    
    @objc func moveCamera(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId", "")

        DispatchQueue.main.async {
            guard let customMapView = self.customWebView?.customMapViews[mapId] else {
                call.reject("map not found")
                return
            }

            let mapCameraPosition = customMapView.mapCameraPosition

            var currentCameraPosition: GMSCameraPosition?;

            let useCurrentCameraPositionAsBase = call.getBool("useCurrentCameraPositionAsBase", true)

            if (useCurrentCameraPositionAsBase) {
                currentCameraPosition = customMapView.getCameraPosition()
            }

            let cameraPosition = call.getObject("cameraPosition", JSObject())
            mapCameraPosition.updateFromJSObject(cameraPosition, baseCameraPosition: currentCameraPosition)

            let duration = call.getInt("duration", 0)

            customMapView.moveCamera(duration)

            call.resolve()
        }
    }

    @objc func addMarker(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId", "")

        DispatchQueue.main.async {
            guard let customMapView = self.customWebView?.customMapViews[mapId] else {
                call.reject("map not found")
                return
            }

            let position = call.getObject("position", JSObject())
            let preferences = call.getObject("preferences", JSObject())

            let marker = self.addMarker([
                "position": position,
                "preferences": preferences
            ], customMapView: customMapView)

            call.resolve(CustomMarker.getResultForMarker(marker, mapId: mapId))
        }
    }

    @objc func addMarkers(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId", "")

        DispatchQueue.main.async {
            guard let customMapView = self.customWebView?.customMapViews[mapId] else {
                call.reject("map not found")
                return
            }

            let markers = List<JSValue>(elements: call.getArray("markers", []))
            self.addMarker(node: markers.first, customMapView: customMapView)

            call.resolve()
        }
    }

    @objc func removeMarker(_ call: CAPPluginCall) {
        let markerId: String = call.getString("markerId", "");

        DispatchQueue.main.async {
            let customMarker = self.customMarkers[markerId];

            if (customMarker != nil) {
                customMarker?.map = nil;
                self.customMarkers[markerId] = nil;
                call.resolve();
            } else {
                call.reject("marker not found");
            }
        }
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
    
    @objc func didBeginDraggingMarker(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_BEGIN_DRAGGING_MARKER);
    }
    
    @objc func didDragMarker(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_DRAG_MARKER);
    }
    
    @objc func didEndDraggingMarker(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_END_DRAGGING_MARKER);
    }
    
    @objc func didTapMyLocationButton(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_MY_LOCATION_BUTTON);
    }

    @objc func didTapMyLocationDot(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_MY_LOCATION_DOT);
    }
    
    @objc func didTapCluster(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_CLUSTER);
    }

    @objc func didTapPoi(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_POI);
    }
    
    @objc func didBeginMovingCamera(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_BEGIN_MOVING_CAMERA);
    }
    
    @objc func didMoveCamera(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_MOVE_CAMERA);
    }
    
    @objc func didEndMovingCamera(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_END_MOVING_CAMERA);
    }

    func setCallbackIdForEvent(call: CAPPluginCall, eventName: String) {
        let mapId: String = call.getString("mapId", "")

        guard let customMapView = self.customWebView?.customMapViews[mapId] else {
            call.reject("map not found")
            return
        }

        call.keepAlive = true;
        let callbackId = call.callbackId;


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
    func addMarker(_ markerData: JSObject, customMapView: CustomMapView) -> GMSMarker {
        let marker = CustomMarker()

        marker.updateFromJSObject(markerData)
        marker.map = customMapView.GMapView

        self.customMarkers[marker.id] = marker

        let preferences = markerData["preferences"] as? JSObject ?? JSObject()

        if let icon = preferences["icon"] as? JSObject {
            if let url = icon["url"] as? String {
                let resizeWidth = icon["width"] as? Int ?? 30
                let resizeHeight = icon["height"] as? Int ?? 30
                self.imageCache.image(at: url, resizeWidth: resizeWidth, resizeHeight: resizeHeight) { [weak self] image in
                    guard let self = self else { return }
                    marker.icon = image
                    
                    if self.markerHandler.shouldCacheMarkers {
                        self.markerHandler.addMarker(marker, mapId: mapView.id)
                    }
                    guard self.markerHandler.shouldClusterMarkers else {
                        marker.map = mapView.GMapView
                        return
                    }
                    let manager = self.markerHandler.clusterManager(for: mapView.id)
                    manager?.add(marker)
                }
            }
        }

        return marker
    }

    func addMarker(node: Node<JSValue>?,
                   customMapView: CustomMapView) {
        guard let node = node else { return }
        let markerData = node.value as? JSObject ?? JSObject()

        self.addMarker(markerData, customMapView: customMapView)

        guard node.next == nil else {
            self.addMarker(node: node.next, customMapView: customMapView)
            return
        }
        self.showMarkers(mapId: mapView.id)
    }
    
    func setupWebView() {
        DispatchQueue.main.async {
            self.customWebView?.isOpaque = false
            self.customWebView?.backgroundColor = .clear

            let javascript = "document.documentElement.style.backgroundColor = 'transparent'"
            self.customWebView?.evaluateJavaScript(javascript)
        }
    }
}

extension CapacitorGoogleMaps: ImageCachable {
    var imageCache: ImageURLLoadable {
        SDWebImageCache.shared
    }
}
