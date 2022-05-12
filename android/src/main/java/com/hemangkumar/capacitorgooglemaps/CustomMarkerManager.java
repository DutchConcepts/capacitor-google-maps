package com.hemangkumar.capacitorgooglemaps;

import com.google.android.libraries.maps.GoogleMap;
import com.google.android.libraries.maps.model.Marker;
import com.google.maps.android.collections.MarkerManager;

import java.util.ArrayList;
import java.util.List;

public class CustomMarkerManager extends MarkerManager {

    private final MapEventsListener mapEventsListener;
    private Collection collection;

    public CustomMarkerManager(
            GoogleMap map,
            MapEventsListener mapEventsListener) {
        super(map);
        this.mapEventsListener = mapEventsListener;
    }

    @Override
    public void onInfoWindowClick(Marker marker) {
        super.onInfoWindowClick(marker);
        mapEventsListener.onInfoWindowClick(marker);
    }

    @Override
    public boolean onMarkerClick(Marker marker) {
        super.onMarkerClick(marker);
        return mapEventsListener.onMarkerClick(marker);
    }

    @Override
    public void onMarkerDragStart(Marker marker) {
        super.onMarkerDragStart(marker);
        mapEventsListener.onMarkerDragStart(marker);
    }

    @Override
    public void onMarkerDrag(Marker marker) {
        super.onMarkerDrag(marker);
        mapEventsListener.onMarkerDrag(marker);
    }

    @Override
    public void onMarkerDragEnd(Marker marker) {
        super.onMarkerDragEnd(marker);
        mapEventsListener.onMarkerDragEnd(marker);
    }

    public java.util.Collection<Marker> getMarkers() {
        if (collection != null)
            return collection.getMarkers();
        else
            return new ArrayList<Marker>();
    }

    @Override
    public Collection newCollection() {
        collection = super.newCollection();
        return collection;
    }
}
