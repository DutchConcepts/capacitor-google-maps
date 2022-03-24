//
//  ImageURLLoadable.swift
//  App
//
//  Created by Elanwave on 3.1.22..
//

import UIKit

protocol ImageURLLoadable {
    static var shared: ImageURLLoadable { get }

    func image(at urlString: String, resizeWidth: Int, resizeHeight: Int, completion: @escaping VoidReturnClosure<UIImage?>)
    func clear(completion:  @escaping NoArgsClosure)
}

protocol ImageCachable {
    var imageCache: ImageURLLoadable { get }
}
