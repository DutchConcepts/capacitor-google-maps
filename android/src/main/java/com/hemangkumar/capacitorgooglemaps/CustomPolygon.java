package com.hemangkumar.capacitorgooglemaps;

import androidx.annotation.Nullable;
import androidx.core.util.Consumer;
import androidx.fragment.app.FragmentActivity;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.util.WebColor;
import com.google.android.libraries.maps.GoogleMap;
import com.google.android.libraries.maps.model.LatLng;
import com.google.android.libraries.maps.model.Polygon;
import com.google.android.libraries.maps.model.PolygonOptions;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

public class CustomPolygon  {
    public final String id = UUID.randomUUID().toString();
    protected JSObject tag = new JSObject();
    private final PolygonOptions options = new PolygonOptions();


    protected PolygonOptions getOptions() {
        return options;
    }

    public void addToMap(FragmentActivity _, GoogleMap googleMap, @Nullable Consumer<Polygon> consumer) {
        final Polygon polygon = googleMap.addPolygon(options);
        polygon.setTag(tag);
        if (consumer != null) {
            consumer.accept(polygon);
        }
    }

    public void updateFromJSObject(JSObject jsObject) {
        loadPoints(jsObject, options::add);
        JSObject jsPreferences = jsObject.getJSObject("preferences");
        if (jsPreferences != null) {
            loadHoles(jsPreferences);
        }
        initPlainFields(jsPreferences);
        saveMetadataToTag(jsPreferences);
    }

    private static void loadPoints(final JSObject jsPoly, Consumer<LatLng> consumer) {
        JSArray jsPoints = JSObjectDefaults.getJSArray(jsPoly, "points", new JSArray());
        int n = jsPoints.length();
        for (int i = 0; i < n; i++) {
            JSObject jsLatLng = JSObjectDefaults.getJSObjectByIndex(jsPoints, i);
            consumer.accept(loadLatLng(jsLatLng));
        }
    }

    private static LatLng loadLatLng(JSObject jsLatLng) {
        double latitude = jsLatLng.optDouble("latitude", 0d);
        double longitude = jsLatLng.optDouble("longitude", 0d);
        return new LatLng(latitude, longitude);
    }

    private void loadHoles(final JSObject preferences) {
        JSArray jsHoles = JSObjectDefaults.getJSArray(preferences, "holes", new JSArray());
        int n = jsHoles.length();
        for (int i = 0; i < n; i++) {
            JSArray jsLatLngArr = JSObjectDefaults.getJSArray(jsHoles, i, new JSArray());
            int m = jsLatLngArr.length();
            List<LatLng> holeList = new ArrayList<>(m);
            for (int j = 0; j < m; j++) {
                JSObject jsLatLon = JSObjectDefaults.getJSObjectByIndex(jsLatLngArr, j);
                holeList.add(loadLatLng(jsLatLon));
            }
            getOptions().addHole(holeList);
        }
    }

    private void initPlainFields(final JSObject jsPreferences) {
        PolygonOptions options = getOptions();

        final float strokeWidth = (float) jsPreferences.optDouble("strokeWidth", 6);
        options.strokeWidth(strokeWidth);


        final int strokeColor = WebColor.parseColor(jsPreferences.optString("strokeColor", "#000000"));
        options.strokeColor(strokeColor);

        final int fillColor = WebColor.parseColor(jsPreferences.optString("fillColor", "#300000FF"));
        options.fillColor(fillColor);


        final boolean isGeodesic = jsPreferences.optBoolean("isGeodesic", false);
        options.geodesic(isGeodesic);


        final float zIndex = (float) jsPreferences.optDouble("zIndex", 0);
        final boolean visibility = jsPreferences.optBoolean("visibility", true);
        final boolean isClickable = jsPreferences.optBoolean("isClickable", false);
        options.zIndex(zIndex);
        options.visible(visibility);
        options.clickable(isClickable);
    }

    private void saveMetadataToTag(JSObject preferences) {
        JSObject jsMetadata = JSObjectDefaults.getJSObjectSafe(
                preferences, "metadata", new JSObject());
        JSObject tag = new JSObject();
        tag.put("id", id);
        tag.put("metadata", jsMetadata);
        this.tag = tag;
    }

    public JSObject getResultFor(Polygon polygon, String mapId) {
        // initialize JSObjects to return
        JSObject jsResult = new JSObject();
        JSObject jsShape = new JSObject();
        JSObject jsPreferences = new JSObject();

        jsResult.put("polygon", jsShape);

        jsShape.put("points", latLongsToJSArray(polygon.getPoints()));
        jsPreferences.put("isGeodesic", polygon.isGeodesic());
        jsPreferences.put("strokeWidth", polygon.getStrokeWidth());
        jsPreferences.put("strokeColor", colorToString(polygon.getStrokeColor()));
        jsPreferences.put("fillColor", colorToString(polygon.getFillColor()));

        // preferences.holes
        JSArray jsHoles = new JSArray();
        for (List<LatLng> hole : polygon.getHoles()) {
            JSArray jsHole = latLongsToJSArray(hole);
            jsHoles.put(jsHole);
        }
        if (jsHoles.length() > 0) {
            jsPreferences.put("holes", jsHoles);
        }

        // metadata
        JSObject tag = (JSObject) polygon.getTag();
        jsPreferences.put("metadata", getMetadata(tag));
        // other preferences
        jsPreferences.put("zIndex", polygon.getZIndex());
        jsPreferences.put("visibility", polygon.isVisible());
        jsPreferences.put("isClickable", polygon.isClickable());

        jsShape.put("preferences", jsPreferences);

        // map id
        jsShape.put("mapId", mapId);

        // id
        String id = tag.optString("id", polygon.getId());
        jsShape.put("id", id);

        return jsResult;
    }

    private static JSObject getMetadata(JSObject tag) {
        return JSObjectDefaults.getJSObjectSafe(tag, "metadata", new JSObject());
    }

    private static JSArray latLongsToJSArray(Collection<LatLng> positions) {
        JSArray jsPositions = new JSArray();
        for (LatLng pos : positions) {
            JSObject jsPos = latLngToJSObject(pos);
            jsPositions.put(jsPos);
        }
        return jsPositions;
    }

    private static JSObject latLngToJSObject(LatLng latLng) {
        JSObject jsPos = new JSObject();
        jsPos.put("latitude", latLng.latitude);
        jsPos.put("longitude", latLng.longitude);
        return jsPos;
    }

    private static String colorToString(int color) {
        int r = ((color >> 16) & 0xff);
        int g = ((color >> 8) & 0xff);
        int b = ((color) & 0xff);
        int a = ((color >> 24) & 0xff);
        if (a != 255) {
            return String.format("#%02X%02X%02X%02X", a, r, g, b);
        } else {
            return String.format("#%02X%02X%02X", r, g, b);
        }
    }

}
