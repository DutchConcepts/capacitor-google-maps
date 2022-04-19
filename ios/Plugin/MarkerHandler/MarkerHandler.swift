import GoogleMapsUtils

final class MarkerHandler: NSObject {
    private (set) var shouldClusterMarkers: Bool = true
    private (set) var shouldCacheMarkers: Bool = true
    var shouldPresentMarkersOnCameraChange: Bool { shouldCacheMarkers }
    
    private var clusterManagers = [String : GMUClusterManager]()
    private var iconProviders = [String : IconProvider]()
    
    private var markerCache: [String: Set<CustomMarker>] = [:]
    
    func addClusterManager(with customMapView: CustomMapView) {
        let iconProvider = IconProvider()
        self.iconProviders[customMapView.id] = iconProvider
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: customMapView.GMapView,
                                                 clusterIconGenerator: iconProvider)
        let clusterManager = GMUClusterManager(map:customMapView.GMapView, algorithm: algorithm,
                                               renderer: renderer)
        self.clusterManagers[customMapView.id] = clusterManager
        clusterManager.setMapDelegate(customMapView)
        clusterManager.cluster()
    }
    
    func cachedMarkers(for mapId: String) -> [CustomMarker] {
        Array(markerCache[mapId] ?? [])
    }
    
    func cluster(_ markers: [CustomMarker], mapId: String?) {
        guard let clusterManager = clusterManagers[mapId ?? ""] else { return }
        DispatchQueue.main.async {
            clusterManager.clearItems()
            clusterManager.add(markers)
        }
    }
    
    func disableClustering(mapId: String) {
        shouldClusterMarkers = false
        clusterManager(for: mapId)?.clearItems()
        clusterManagers.removeValue(forKey: mapId)
    }
    
    func addMarker(_ marker: CustomMarker, mapId: String) {
        guard var cache = markerCache[mapId] else {
            var cache = Set<CustomMarker>()
            cache.insert(marker)
            markerCache[mapId] = cache
            return
        }
        cache.insert(marker)
        markerCache[mapId] = cache
    }
    
    func clusterManager(for mapId: String?) -> GMUClusterManager? {
        return clusterManagers[mapId ?? ""]
    }
    
    func removeMarker(_ marker: CustomMarker, mapId: String) {
        guard let cacheDic = markerCache.first (where: {
            $0.value.contains(marker)
        }) else { return }
        
        var cache = cacheDic.value
        let mapId = cacheDic.key
        
        cache.remove(marker)
        markerCache[mapId] = cache
    }
    
    func updateClusterIcon(mapId: String, icons: [Int: String]?, completion: NoArgsClosure?) {
        guard let clusterIcons = icons else { return }
        iconProviders[mapId]?.fetchIcons(icons: clusterIcons, completion: completion)
    }
    
    func clearCache(mapId: String) {
        markerCache.removeValue(forKey: mapId)
    }
    
    func disableCaching() {
        shouldCacheMarkers = false
        markerCache.removeAll()
    }
}

extension MarkerHandler: ImageCachable {
    var imageCache: ImageURLLoadable {
        SDWebImageCache.shared
    }
}
