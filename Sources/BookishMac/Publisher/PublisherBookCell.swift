// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class PublisherBookCell: NSTableCellView, ActionContextProvider, ManagedObjectTableCell {
    func setup(for view: ManagedObjectViewController, row: Int, item: NSManagedObject) {
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


