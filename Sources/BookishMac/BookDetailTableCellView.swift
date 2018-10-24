// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class BookDetailTableCellView: NSTableCellView {
    
}

extension BookDetailTableCellView: BindableCellView {
    func setup(for view: BookDetailViewController, row: Int, info: DetailDataSource.RowInfo) {
        assert(!info.isPerson)
        if let subview = textField, let index = view.indexView.indexArray {
            let detail = view.source.details(for: row)
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "detail-\(detail.binding)")
            subview.bind(NSBindingName(rawValue: "value"), to:index, withKeyPath:"selection.\(detail.binding)", options: [:])

            objectValue = index.selection as? NSObject
        }
    }
}
