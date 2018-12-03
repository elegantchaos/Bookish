// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import AppKit
import Actions
import BookishModel

class SeriesEntryCell: NSTableCellView, ActionContextProvider, ManagedObjectTableCell {
    func setup(for view: ManagedObjectViewController, row: Int, item: NSManagedObject) {
        if let entry = item as? Entry, let name = entry.book?.name {
            objectValue = item
            textField?.stringValue = "#\(entry.index): \(name)"
            validateButtons()
        }
    }
    
    func provide(context: ActionContext) {
        if let entry = objectValue as? Entry {
            context.info[BookAction.bookKey] = entry.book
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}


