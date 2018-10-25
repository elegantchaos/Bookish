// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class PersonBookCell: NSTableCellView, ActionContextProvider, PersonDetailTableCell {
    func setup(for view: PersonDetailViewController, row: Int, item: NSManagedObject) {
        if let book = item as? Book, let name = book.name {
            objectValue = item
            textField?.stringValue = name
            validateButtons()
        }
    }
    
    func provide(context: ActionContext) {
        context.info[BookAction.bookKey] = objectValue as? Book
    }
    
    func keyView() -> NSView? {
        return textField
    }
}


