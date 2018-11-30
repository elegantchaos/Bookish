// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookDateCell: NSTableCellView {
    @IBOutlet weak var infoButton: NSButton!
}

extension BookDateCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .detail)
        if let subview = textField,
            let index = view.indexView.indexArray,
            let transformer = ValueTransformer(forName: NSValueTransformerName(rawValue: "DateToString")) {
            let detail = view.source.details(for: row)
            let options: [NSBindingOption:Any] = [
                .valueTransformer: transformer,
            ]
            
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "date-detail-\(detail.binding)")
            subview.bind(NSBindingName(rawValue: "value"), to:index, withKeyPath:"selection.\(detail.binding)", options: options)
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}
