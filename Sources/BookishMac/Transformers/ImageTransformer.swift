// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishCore

class ImageTransformer: ValueTransformer {
    let placeholderName: String
    let imageKey: String
    let urlKey: String
    let cache: NSImageCache
    
    init(placeholder: String, imageKey: String = "image", urlKey: String = "imageURL", cache: NSImageCache) {
        self.placeholderName = placeholder
        self.imageKey = imageKey
        self.urlKey = urlKey
        self.cache = cache
    }
    
    lazy var placeholder: NSImage? = {
        return NSImage(named: placeholderName)
    }()
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let obj = value as? NSObject {
            if let data = obj.value(forKey: imageKey) as? Data, let image = NSImage(data: data) {
                return image
            } else if let urlString = obj.value(forKey: urlKey) as? String, let url = URL(string: urlString) {
                cache.image(for: url, callback: { (image) in
                    return image
                })
            }
        }

        return placeholder
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let image = value as? NSImage {
            if image == placeholder {
                return nil
            } else {
                if let rep = image.tiffRepresentation {
                    return rep
                }
            }
        }
        
        return value
    }
    
}
