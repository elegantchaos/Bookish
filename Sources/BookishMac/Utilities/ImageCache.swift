// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 31/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class ImageCache {
    let queue = DispatchQueue(label: "image-cache")
    typealias ImageCallback = (NSImage) -> Void
    
    func image(for url: URL, callback: @escaping ImageCallback) {
        queue.async {
            if let image = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    callback(image)
                }
            }
        }
    }
}
