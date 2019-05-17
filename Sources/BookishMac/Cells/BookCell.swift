// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookCell: NSTableCellView, DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        if let item = row as? BookDetailItem, let book = item.book, let name = book.name {
            objectValue = book
            textField?.stringValue = name
            application.actionManager.validateControls(of: self)
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}

extension BookCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[BookAction.bookKey] = objectValue as? Book
    }
}
