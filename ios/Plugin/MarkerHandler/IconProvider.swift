//
//  IconProvider.swift
//  Capacitor
//
//  Created by Elanwave on 21.3.22..
//

import GoogleMapsUtils

class IconProvider: NSObject, GMUClusterIconGenerator {
    var icons: [Int: String] = [:] 
    var iconImages: [UIImage] = []
    
    var onIconsFetched: NoArgsClosure?
    
    public func icon(forSize size: UInt) -> UIImage! {
        for (index, limit) in icons.map({ $0.key }).sorted().enumerated() {
            if size < limit && iconImages.count > index {
                return iconImages[index]
            }
        }
        return UIImage()
    }
    
    func fetchIcons(completion: NoArgsClosure?) {
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
            self?.iconImages.append(image.resize(targetSize: CGSize(width: 30, height: 30)) ?? UIImage())
            self?.fetchIcons(element: element?.next, completion: completion)
        }
    }
}

extension IconProvider: ImageCachable {
    var imageCache: ImageURLLoadable {
        SDWebImageCache.shared
    }
}
