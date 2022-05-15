package com.hemangkumar.capacitorgooglemaps;

import com.google.android.libraries.maps.model.LatLng;
import com.google.android.libraries.maps.model.Marker;
import com.google.maps.android.PolyUtil;

import java.util.Collection;
import java.util.Map;
import java.util.WeakHashMap;

public class MarkerVisibilityCorrector {
    private static final double EARTH_RADIUS = 6371.00; // Radius in Kilometers default
    private CustomMarkerManager markerManager;
    private CustomClusterRenderer clusterRenderer;
    private final Map<String, Marker> markers;
    private final Map<String, ShapePolygon> polygons;
    private final Map<String, ShapeCircle> circles;
    private final Map<Marker, Boolean> savedMarkerVisibilities = new WeakHashMap<>();

    private boolean correctionMode;

    public MarkerVisibilityCorrector(final Map<String, Marker> markers,
                                     final Map<String, ShapePolygon> polygons,
                                     final Map<String, ShapeCircle> circles) {
        this.markers = markers;
        this.polygons = polygons;
        this.circles = circles;
    }

    public void setCorrectionMode(boolean enabled) {
        correctionMode = enabled;
    }

    public void setMarkerManager(CustomMarkerManager markerManager) {
        this.markerManager = markerManager;
    }

    public void setClusterRenderer(CustomClusterRenderer clusterRenderer) {
        this.clusterRenderer = clusterRenderer;
    }

    public void clear() {
        savedMarkerVisibilities.clear();
    }

    public void remove(Marker marker) {
        savedMarkerVisibilities.remove(marker);
    }

    public void correctMarkerVisibility() {
        if (!correctionMode) return;
        correctMarkerVisibility(markers.values());
        if (clusterRenderer != null) {
            correctMarkerVisibility(clusterRenderer.getClusteredMarkers());
        }
        correctMarkerVisibility(markerManager.getMarkers());
    }

    private void correctMarkerVisibility(Collection<Marker> markers) {
        for (Marker marker : markers) {
            boolean isCovered = isCoveredWithShape(
                    marker.getPosition(),
                    this.polygons.values(),
                    this.circles.values()
            );
            updateVisibility(isCovered, marker.isVisible(), marker);
        }
    }

    public void correctMarkerVisibility(Marker marker) {
        if (!correctionMode) return;
        updateVisibility(isCoveredWithShape(marker.getPosition()), marker.isVisible(), marker);
    }

    public boolean isCoveredWithShape(LatLng pos) {
        if (!correctionMode) return false;
        return isCoveredWithShape(
                pos,
                polygons.values(),
                circles.values()
        );
    }

    private boolean isCoveredWithShape(LatLng pos,
                                       Iterable<ShapePolygon> polygons,
                                       Iterable<ShapeCircle> circles) {
        for (ShapePolygon polygon : polygons) {
            if (polygon.isAboveMarkers() && polygon.isVisible() &&
                    (PolyUtil.containsLocation(pos, polygon.getPoints(), polygon.isGeodesic())
                            || PolyUtil.isLocationOnEdge(pos, polygon.getPoints(), polygon.isGeodesic()))) {
                return true;
            }
        }
        for (ShapeCircle circle : circles) {
            if (circle.isAboveMarkers() && circle.isVisible() &&
                    (calculateDistance(circle.getCenter(), pos) <= circle.getRadius())) {
                return true;
            }
        }
        return false;
    }

    public void updateVisibility(boolean shouldHide, boolean origVisibility, Marker marker) {
        if (!correctionMode) return;
        if (shouldHide) {
            if (!savedMarkerVisibilities.containsKey(marker)) {
                savedMarkerVisibilities.put(marker, origVisibility);
            }
            marker.setVisible(false);
        } else {
            Boolean visibility = savedMarkerVisibilities.remove(marker);
            if (visibility != null) {
                marker.setVisible(visibility);
            }
        }
    }

    private static Double calculateDistance(LatLng p1, LatLng p2) {
        // http://www.codecodex.com/wiki/Calculate_Distance_Between_Two_Points_on_a_Globe
        double dLat = Math.toRadians(p2.latitude - p1.latitude);
        double dLon = Math.toRadians(p2.longitude - p1.longitude);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(p1.latitude)) * Math.cos(Math.toRadians(p2.latitude)) *
                        Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.asin(Math.sqrt(a));
        return EARTH_RADIUS * c;
    }
}
