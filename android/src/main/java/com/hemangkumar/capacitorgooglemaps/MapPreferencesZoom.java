package com.hemangkumar.capacitorgooglemaps;

import androidx.annotation.Nullable;

import com.getcapacitor.JSObject;


public class MapPreferencesZoom  {

    public Integer minZoom;
    public Integer maxZoom;

    public static final String MIN_ZOOM_KEY = "minZoom";
    public static final String MAX_ZOOM_KEY = "maxZoom";

    public MapPreferencesZoom() {
        this.minZoom = 8;
        this.maxZoom = 22;
    }

    public void updateFromJSObject(@Nullable JSObject jsObject) {
        if (jsObject != null) {
            Integer minZoom = jsObject.getInteger(MIN_ZOOM_KEY, 8);
            if (minZoom != null) {
                this.minZoom = minZoom;
            }

            Integer maxZoom = jsObject.getInteger(MAX_ZOOM_KEY, 22);
            if (maxZoom != null) {
                this.maxZoom = maxZoom;
            }
        }
    }
}
