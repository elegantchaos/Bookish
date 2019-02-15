// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class RelationshipCell: NSTableCellView, DetailTableCell {
    func setup(for row: DetailItem, of view: GenericDetailController) {
        if let item = row as? PersonDetailItem, let role = item.relationship?.role, let name = role.name {
            objectValue = item
            textField?.stringValue = "Books as \(name)"
            validateButtons()
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}


