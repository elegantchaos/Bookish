// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import AppKit

class BookHeadingCell: NSTableCellView, DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        if let field = subviews.first as? NSTextField {
            let text = row.heading
            field.stringValue = text
            field.isEditable = false
            field.isSelectable = !text.isEmpty
        }
    }
    
    func keyView() -> NSView? {
        return nil
    }

}
