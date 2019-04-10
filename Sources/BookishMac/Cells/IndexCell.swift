// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/04/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class IndexCell: NSTableCellView {
    override var objectValue: Any? {
        didSet {
            if let object = objectValue as? ModelObject {
                updateImage(for: object)
            }
        }
    }
    
    fileprivate func updateImage(for object: ModelObject) {
        if let imageView = imageView {
            if let data = object.value(forKey: "image") as? Data, let image = NSImage(data: data) {
                imageView.image = image
                
            } else {
                let placeholderName = type(of: object).entityPlaceholder
                imageView.image = NSImage(named: placeholderName)
                if let urlString = object.value(forKey: "imageURL") as? String, let url = URL(string: urlString) {
                    application.imageCache.image(for: url) { (image) in
                        imageView.image = image
                    }
                }
            }
        }
    }
}
