// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import AppKit

class BookHeadingCell: NSTableCellView, BookDetailTableCell {
    func setup(for detailView: BookDetailViewController, row: Int, isPerson: Bool) {
        let source = detailView.source
        if let field = subviews.first as? NSTextField {
            if isPerson {
                field.stringValue = source.person(for: row).role?.name ?? "<unknown role>"
            } else {
                field.stringValue = source.details(for: row).label
            }
        }
    }
    
    func keyView() -> NSView? {
        return nil
    }

}
