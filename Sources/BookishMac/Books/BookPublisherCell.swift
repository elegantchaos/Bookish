// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 30/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookPublisherCell: NSTableCellView {
    @IBOutlet weak var publisherField: NSTextField!
    var detailView: BookDetailViewController?
}

extension BookPublisherCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .publisher)
        let source = view.source
        detailView = view
        let publisher = source.publisher(for: row)
        objectValue = publisher
        if let name = publisher.name {
            publisherField?.stringValue = name
        }
    }
    
    func keyView() -> NSView? {
        return publisherField
    }
}

extension BookPublisherCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PublisherAction.publisherKey] = objectValue as? Publisher
    }
    
}
