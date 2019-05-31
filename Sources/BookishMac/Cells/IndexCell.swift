// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/04/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class IndexCell: NSTableCellView {
    override var objectValue: Any? {
        didSet {
            if let object = objectValue as? ModelEntityCommon, let view = imageView {
                object.setImage(for: view, cache: application.imageCache)
            }
        }
    }
    
    override var backgroundStyle: NSView.BackgroundStyle {
        get {
            return super.backgroundStyle
        }
        
        set (value) {
            switch value {
            case .emphasized:
                textField?.textColor = NSColor(named: "Bookish Index Text Selected")
                
            default:
                textField?.textColor = NSColor(named: "Bookish Index Text")
            }
            super.backgroundStyle = value
        }
    }
    
}
