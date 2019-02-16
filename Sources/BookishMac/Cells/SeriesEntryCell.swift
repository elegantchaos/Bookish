// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import AppKit
import Actions
import BookishModel

class SeriesEntryCell: NSTableCellView, ActionContextProvider, DetailTableCell {
    func setup(for row: DetailItem, of view: GenericDetailController) {
        if let item = row as? PersonBookDetailItem, let book = item.book, let name = book.name {
            objectValue = item
            textField?.stringValue = name
            validateButtons()
        }
//        if let item = row as? SeriesDetailItem, let entry = item.series, let name = entry.book?.name {
//            objectValue = item
//            textField?.stringValue = "#\(entry.position): \(name)"
//            validateButtons()
//        }
    }
    
    func provide(context: ActionContext) {
        if let entry = objectValue as? SeriesEntry {
            context.info[BookAction.bookKey] = entry.book
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}


