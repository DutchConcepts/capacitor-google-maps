import GoogleMapsUtils

final class MarkerHandler: NSObject {
    var shouldClusterMarkers: Bool = true
    var shouldCacheMarkers: Bool = true
    var shouldPresentMarkersOnCameraChange: Bool { shouldCacheMarkers }
    
    let urlHeart = "https://www.iconpacks.net/icons/1/free-icon-heart-492.png"
    let urlHand = "https://www.iconpacks.net/icons/1/free-icon-click-1263.png"
    
    private var clusterManagers = [String : GMUClusterManager]()
    var clusterIcon: UIImage?
    
    private var markerCache: [String: Set<CustomMarker>] = [:]
    
    func addClusterManager(with customMapView: CustomMapView) {
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: customMapView.GMapView,
                                                 clusterIconGenerator: self)
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
        guard var cache = markerCache[mapId] else { return }
        cache.remove(marker)
    }
    
    func updateClusterIcon(completion: NoArgsClosure?) {
        imageCache.image(at: urlHeart) { image in
            self.clusterIcon = image
            completion?()
        }
    }
}

extension MarkerHandler: GMUClusterIconGenerator {
    public func icon(forSize size: UInt) -> UIImage! {
        if size == 1 {
            return clusterIcon?.resize(targetSize: CGSize(width: 30, height: 30))
        } else if size < 50 {
            return clusterIcon?.resize(targetSize: CGSize(width: 40, height: 40))?.addText(NSString(format: "%d", size), atPoint: .zero)
        } else if size < 200 {
            return clusterIcon?.resize(targetSize: CGSize(width: 50, height: 50))?.addText(NSString(format: "%d", size), atPoint: .zero)
        } else {
            return clusterIcon?.resize(targetSize: CGSize(width: 60, height: 60))?.addText(NSString(format: "%d", size), atPoint: .zero)
        }
    }
}

extension MarkerHandler: ImageCachable {
    var imageCache: ImageURLLoadable {
        SDWebImageCache.shared
    }
}
