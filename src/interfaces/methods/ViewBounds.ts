import { ViewBounds } from "./../../definitions";

export interface ViewBoundsOptions {
  /**
   * The identifier of the map to which this method should be applied.
   *
   * @since 2.0.0
   */
  mapId: string;
}

export interface ViewBoundsResult {
  /**
   * @since 2.0.0
   */
  bounds: ViewBounds;
}
