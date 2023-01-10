import {
  MapAppearance,
  MapControls,
  MapGestures,
  MapZoom,
} from "./../../../definitions";

export interface MapPreferences {
  /**
   * @since 2.0.0
   */
  gestures?: MapGestures;
  /**
   * @since 2.0.0
   */
  controls?: MapControls;
  /**
   * @since 2.0.0
   */
  appearance?: MapAppearance;

  zoom?: MapZoom;

  padding?: any; // @todo: Sets padding on the map.

  liteMode?: boolean; // @todo
}
