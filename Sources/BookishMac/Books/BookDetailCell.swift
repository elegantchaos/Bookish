// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class BookDetailCell: NSTableCellView {
    
}

extension BookDetailCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: Int, isPerson: Bool) {
        assert(!isPerson)
        if let subview = textField, let index = view.indexView.indexArray {
            let detail = view.source.details(for: row)
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "detail-\(detail.binding)")
            subview.bind(NSBindingName(rawValue: "value"), to:index, withKeyPath:"selection.\(detail.binding)", options: [:])
            subview.isEditable = view.editing
            objectValue = index.selection as? NSObject
        }
    }

    func keyView() -> NSView? {
        return textField
    }
}
