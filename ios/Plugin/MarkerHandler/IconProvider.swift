import GoogleMapsUtils

class IconProvider: NSObject, GMUClusterIconGenerator {
    private var icons: [Int: String] = [:]
    private var iconImages: [String: UIImage] = [:]
    
    var onIconsFetched: NoArgsClosure?
    
    public func icon(forSize size: UInt) -> UIImage! {
        for limit in icons.keys.sorted() {
            if size < limit {
                return iconImages[icons[limit] ?? ""] ?? UIImage()
            }
        }
        return iconImages.first?.value ?? UIImage()
    }
    
    func fetchIcons(icons: [Int: String], completion: NoArgsClosure?) {
        self.icons = icons
        let imageUrls = icons.map { $0.value }
        let urlList: List<String> = List(elements: imageUrls)
        fetchIcons(element: urlList.first) {
            completion?()
        }
    }
    
    private func fetchIcons(element: Node<String>?, completion: NoArgsClosure?) {
        guard let urlString = element?.value else {
            completion?()
            return
        }
        
        imageCache.image(at: urlString) { [weak self] resultImage in
            guard let image = resultImage else {
                self?.fetchIcons(element: element?.next, completion: completion)
                return
            }
            self?.iconImages[urlString] = image
            self?.fetchIcons(element: element?.next, completion: completion)
        }
    }
}

extension IconProvider: ImageCachable {
    var imageCache: ImageURLLoadable {
        SDWebImageCache.shared
    }
}
