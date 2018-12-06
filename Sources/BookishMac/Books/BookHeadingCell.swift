// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import AppKit

class BookHeadingCell: NSTableCellView, BookDetailTableCell {
    func setup(for detailView: BookDetailViewController, row: DetailDataSource.RowInfo) {
        let source = detailView.source
        if let field = subviews.first as? NSTextField {
            field.stringValue = source.heading(for: row)
        }
    }
    
    func keyView() -> NSView? {
        return nil
    }

}
