// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class CoverImageTransformer: ValueTransformer {
    static let name = NSValueTransformerName(rawValue: "CoverImage")
    
    var placeholder: NSImage?
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let data = value as? Data, let image = NSImage(data: data) {
            return image
        } else {
            if placeholder == nil {
                placeholder = NSImage(named: "CoverPlaceholder")
            }
            
            return placeholder
        }
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
