// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class SectionCell: NSTableCellView, DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        if let item = row as? SectionDetailItem {
            textField?.stringValue = item.kind
            application.actionManager.validateControls(of: self)
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}


