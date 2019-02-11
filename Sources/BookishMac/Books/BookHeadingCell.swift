// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import AppKit

class BookHeadingCell: NSTableCellView, BookDetailTableCell {
    func setup(for detailView: BookDetailViewController, row: DetailItem) {
        if let field = subviews.first as? NSTextField {
            field.stringValue = row.heading
        }
    }
    
    func keyView() -> NSView? {
        return nil
    }

}
