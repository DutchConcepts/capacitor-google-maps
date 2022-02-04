import Foundation
import Capacitor
import GoogleMaps

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}


@objc(CapacitorGoogleMaps)

public class CapacitorGoogleMaps: CustomMapViewEvents {

    var GOOGLE_MAPS_KEY: String = "";

    var customMapViews = [String : CustomMapView]();

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
            let customMapView : CustomMapView = CustomMapView(customMapViewEvents: self);

            self.bridge?.saveCall(call)
            customMapView.savedCallbackIdForCreate = call.callbackId;
            
            let boundingRect = call.getObject("boundingRect", JSObject());
            customMapView.boundingRect.updateFromJSObject(boundingRect);
            
            let mapCameraPosition = call.getObject("cameraPosition", JSObject());
            customMapView.mapCameraPosition.updateFromJSObject(mapCameraPosition);

            let preferences = call.getObject("preferences", JSObject());
            customMapView.mapPreferences.updateFromJSObject(preferences);
            
            let innerElements = call.getArray("innerElements", JSArray())
            
            self.bridge?.webView?.isOpaque = false
            self.bridge?.webView?.backgroundColor = .clear
   
            let passThroughView = PassThroughView(frame:(self.bridge?.viewController?.view.frame)!)
   
            self.bridge?.viewController?.view = passThroughView
            
            passThroughView.insertSubview(self.bridge?.webView as! UIView, at: 0)
            passThroughView.insertSubview(customMapView.view, at: 0)
            passThroughView.setInnerElements(elements: innerElements)
            
            
            customMapView.GMapView.delegate = customMapView;
            self.customMapViews[customMapView.id] = customMapView;
            
            
        }
    }
    
    @objc func disableMap(_ call: CAPPluginCall){
        let mapId: String = call.getString("mapId")!;
        DispatchQueue.main.async {
            let customMapView = self.customMapViews[mapId];

            if (customMapView != nil) {
                customMapView?.view.isUserInteractionEnabled = false
            } else {
                call.reject("map not found");
            }
        }
    }
    
    @objc func enableMap(_ call: CAPPluginCall){
        let mapId: String = call.getString("mapId")!
        DispatchQueue.main.async {
            let customMapView = self.customMapViews[mapId];

            if (customMapView != nil) {
                customMapView?.view.isUserInteractionEnabled = true
            } else {
                call.reject("map not found");
            }
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

    @objc func addMarker(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId", "");

        DispatchQueue.main.async {
            let customMapView = self.customMapViews[mapId];

            if (customMapView != nil) {
                let preferences = call.getObject("preferences", JSObject());

                let marker = CustomMarker();
                marker.updateFromJSObject(preferences: preferences);

                marker.map = customMapView?.GMapView;

                self.customMarkers[marker.id] = marker;

                call.resolve(CustomMarker.getResultForMarker(marker));
            } else {
                call.reject("map not found");
            }
        }
    }
    
    @objc func addMarkers(_ call: CAPPluginCall) {
        let mapId: String = call.getString("mapId", "");

        DispatchQueue.main.async {
            let customMapView = self.customMapViews[mapId];

            if (customMapView != nil) {
                let markers = call.getArray("markers", []);
                
                for item in markers {
                    let markerObject = item as? JSObject ?? JSObject();

                    let preferences = markerObject["preferences"] as? JSObject ?? JSObject();

                    let marker = CustomMarker();
                    marker.updateFromJSObject(preferences: preferences);

                    marker.map = customMapView?.GMapView;

                    self.customMarkers[marker.id] = marker;
                }

                call.resolve();
            } else {
                call.reject("map not found");
            }
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
