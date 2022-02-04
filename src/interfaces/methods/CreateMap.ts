import {
  GoogleMap,
  BoundingRect,
  MapPreferences,
  CameraPosition,
} from "./../../definitions";

export interface CreateMapOptions {
  /**
   * @since 2.0.0
   */
  element?: HTMLElement;
  /**
   * @since 2.0.0
   */
  boundingRect?: BoundingRect;
  /**
   * See CameraPosition
   *
   * @since 2.0.0
   */
  cameraPosition: CameraPosition;
  /**
   * @since 2.0.0
   */
  preferences?: MapPreferences;
  /**
  * @since 2.0.0
  */
  internalBounds?: [];
}

export interface CreateMapResult {
  /**
   * @since 2.0.0
   */
  googleMap: GoogleMap;
}
