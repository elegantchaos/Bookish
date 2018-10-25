// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class PersonRoleCell: NSTableCellView, PersonDetailTableCell {
    func setup(for view: PersonDetailViewController, row: Int, item: NSManagedObject) {
                      if let role = item as? Role, let name = role.name {
            objectValue = item
            textField?.stringValue = name
            validateButtons()
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}


