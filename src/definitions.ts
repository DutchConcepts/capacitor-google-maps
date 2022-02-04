import { PluginListenerHandle } from "@capacitor/core";

import {
  // methods
  InitializeOptions,
  CreateMapOptions,
  CreateMapResult,
  UpdateMapOptions,
  UpdateMapResult,
  MoveCameraOptions,
  MoveCameraResult,
  ElementFromPointResultOptions,
  AddMarkerOptions,
  AddMarkerResult,
  DisableMapOptions,
  // events
  DidTapInfoWindowCallback,
  DidCloseInfoWindowCallback,
  DidTapMapCallback,
  DidLongPressMapCallback,
  DidTapMarkerCallback,
  DidTapMyLocationButtonCallback,
  DidTapMyLocationDotCallback,
} from "./interfaces";

export type CallbackID = string;

export interface DefaultEventOptions {
  mapId: string;
}

export interface DefaultEventWithPreventDefaultOptions {
  mapId: string;
  preventDefault?: boolean;
}

export interface DidRequestElementFromPointResult {
  eventChainId: string;
  point?: {
    x: number;
    y: number;
  };
}

export interface CapacitorGoogleMapsPlugin {
  initialize(options: InitializeOptions): Promise<void>;

  createMap(options: CreateMapOptions): Promise<CreateMapResult>;

  updateMap(options: UpdateMapOptions): Promise<UpdateMapResult>;

  moveCamera(options: MoveCameraOptions): Promise<MoveCameraResult>;

  addMarker(options: AddMarkerOptions): Promise<AddMarkerResult>;

  disableMap(options: DisableMapOptions): Promise<void>;

  removeMarker(markerId: string): Promise<void>;

  didTapInfoWindow(
    options: DefaultEventOptions,
    callback: DidTapInfoWindowCallback
  ): Promise<CallbackID>;

  didCloseInfoWindow(
    options: DefaultEventOptions,
    callback: DidCloseInfoWindowCallback
  ): Promise<CallbackID>;

  didTapMap(
    options: DefaultEventOptions,
    callback: DidTapMapCallback
  ): Promise<CallbackID>;

  didLongPressMap(
    options: DefaultEventOptions,
    callback: DidLongPressMapCallback
  ): Promise<CallbackID>;

  didTapMarker(
    options: DefaultEventWithPreventDefaultOptions,
    callback: DidTapMarkerCallback
  ): Promise<CallbackID>;

  didTapMyLocationButton(
    options: DefaultEventWithPreventDefaultOptions,
    callback: DidTapMyLocationButtonCallback
  ): Promise<CallbackID>;

  didTapMyLocationDot(
    options: DefaultEventOptions,
    callback: DidTapMyLocationDotCallback
  ): Promise<CallbackID>;

  /**
   * After `didRequestElementFromPoint` fires, this method is used to let the WebView know whether or not to delegate the touch event to a certain MapView.
   * It is handled automatically and you should probably not use it.
   */
  elementFromPointResult(options: ElementFromPointResultOptions): Promise<void>;

  /**
   * This listens for touch events on the WebView.
   * It is handled automatically and you should probably not use it.
   */
  addListener(
    eventName: "didRequestElementFromPoint",
    listenerFunc: (result: DidRequestElementFromPointResult) => void
  ): PluginListenerHandle;
}

export * from "./interfaces";

// methods to implement:
// - GoogleMap.animateCamera
// - GoogleMap.snapshot
// - GoogleMap.setInfoWindowAdapter (HTMLElement)

// listeners to implement:
// - a lot
