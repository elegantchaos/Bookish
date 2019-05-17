// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/03/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import AppKit
import Actions
import BookishModel

class EntryCell: NSTableCellView, DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        if let item = row as? SeriesEntryDetailItem, let entry = item.entry, let book = entry.book, let name = book.name {
            objectValue = entry
            textField?.stringValue = name
            application.actionManager.validateControls(of: self)
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}

extension EntryCell: ActionContextProvider {
    func provide(context: ActionContext) {
        let entry = objectValue as? SeriesEntry
        context.info[BookAction.bookKey] = entry?.book
    }
}
