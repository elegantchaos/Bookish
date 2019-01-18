// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import AppKit


class BookPersonHeadingCell: NSTableCellView, BookDetailTableCell {
    @IBOutlet weak var rolePopup: ColoredPopUpButton!
    func setup(for detailView: BookDetailViewController, row: DetailDataSource.RowInfo) {
        rolePopup.setItemStyles()
        let source = detailView.source
        if let field = subviews.first as? NSTextField {
            field.stringValue = source.heading(for: row)
        }
    }
    
    func keyView() -> NSView? {
        return nil
    }
    
}
