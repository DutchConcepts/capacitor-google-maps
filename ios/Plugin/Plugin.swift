import Foundation
import Capacitor
import GoogleMaps
import GoogleMapsUtils
import SDWebImage
import UIKit

@objc(CapacitorGoogleMaps)
public class CapacitorGoogleMaps: CustomMapViewEvents {
    var GOOGLE_MAPS_KEY: String = "";

    var customMapViews = [String : CustomMapView]();
    
    let markerHandler = MarkerHandler()

    var customMarkers = [String : CustomMarker]();

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
            
            self.addButtons(customMapView: customMapView)
            
            customMapView.GMapView.delegate = customMapView
            self.customMapViews[customMapView.id] = customMapView
            
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
    
    func addButtons(customMapView: CustomMapView) {
        let clusterButton = UIButton()
        clusterButton.addTarget(self, action: #selector(self.cluster), for: .touchUpInside)
        clusterButton.setTitle("Cluster", for: .normal)
        clusterButton.frame = CGRect(x: 20, y: 50, width: 100, height: 30)
        clusterButton.backgroundColor = .red
        customMapView.GMapView.addSubview(clusterButton)
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
        guard let mapId = call.getString("mapId") else {
            call.reject("map not found")
            return
        }

        DispatchQueue.main.async {
            let customMapView = self.customMapViews[mapId]

            if (customMapView != nil) {
                let preferences = call.getObject("preferences", JSObject())
                CATransaction.begin()
                customMapView?.mapPreferences.updateFromJSObject(preferences)

                customMapView?.invalidateMap()
                CATransaction.commit()
            } else {
                call.reject("map not found")
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
            
            CATransaction.begin()
            let camera = GMSMutableCameraPosition.camera(withLatitude: mapCameraPosition.latitude,
                                                         longitude: mapCameraPosition.longitude,
                                                         zoom: customMapView.GMapView.camera.zoom)
            customMapView.GMapView.animate(to: camera)
            CATransaction.commit()
            
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
            
            self.customMarkers[marker.id] = marker
            if let url = call.getObject("icon")?["url"] as? String {
                self.imageCache.image(at: url) { image in
                    marker.icon = image
                    if self.markerHandler.shouldCacheMarkers {
                        self.markerHandler.addMarker(marker, mapId: customMapView.id)
                    }
                    guard self.markerHandler.shouldClusterMarkers else {
                        marker.map = customMapView.GMapView
                        return
                    }
                    let manager = self.markerHandler.clusterManager(for: mapId)
                    manager?.add(marker)
                }
            }
            call.resolve(CustomMarker.getResultForMarker(marker))
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

    @objc func didTapMyLocationButton(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_MY_LOCATION_BUTTON);
    }

    @objc func didTapMyLocationDot(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_MY_LOCATION_DOT);
    }
    
    @objc func didTapCluster(_ call: CAPPluginCall) {
        setCallbackIdForEvent(call: call, eventName: CustomMapView.EVENT_DID_TAP_CLUSTER);
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
     
        customMarkers[marker.id] = marker
        if let url = (markerObject["icon"] as? JSObject)?["url"] as? String {
            imageCache.image(at: url) { [weak self] image in
                
                guard let self = self else { return }
                marker.icon = image
                
                if self.markerHandler.shouldCacheMarkers {
                    self.markerHandler.addMarker(marker, mapId: mapView.id)
                }
                guard self.markerHandler.shouldClusterMarkers else {
                    marker.map = mapView.GMapView
                    self.addMarker(node: node.next, mapView: mapView)
                    return
                }
                let manager = self.markerHandler.clusterManager(for: mapView.id)
                manager?.add(marker)
                guard node.next == nil else {
                    self.addMarker(node: node.next, mapView: mapView)
                    return
                }
                self.showMarkers(mapId: mapView.id)
            }
        }
    }
    
    func setupWebView() {
        self.webView?.isOpaque = false
        self.webView?.backgroundColor = .clear
        self.webView?.scrollView.backgroundColor = .clear
        self.webView?.scrollView.isOpaque = false
        self.webView?.scrollView.canCancelContentTouches = false
    }
}

extension CapacitorGoogleMaps: ImageCachable {
    var imageCache: ImageURLLoadable {
        SDWebImageCache.shared
    }
}



extension WKWebView {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for view in subviews {
            let convertedPoint = self.convert(point, to: view)
            guard view is GMSMapView,
                  let mapView = view.hitTest(convertedPoint, with: event),
                  scrollView.layer.pixelColorAtPoint(point: self.convert(point, to: scrollView)).cgColor.alpha == 0.0
                  //layer.pixelColorAtPoint(point: point) == mapView.layer.pixelColorAtPoint(point: convertedPoint)
            else { continue }
            return mapView
        }
        return super.hitTest(point, with: event)
    }
}
