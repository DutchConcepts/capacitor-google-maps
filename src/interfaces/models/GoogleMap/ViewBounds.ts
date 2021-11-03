import { LatLng } from "../../../definitions";

export interface ViewBounds {
  /**
   * @since 2.0.0
   */
  farLeft: LatLng;
  farRight: LatLng;
  nearLeft: LatLng;
  nearRight: LatLng;
}
