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

extension BookDateCell: DetailTableCell {
    func setup(for row: DetailItem, of view: GenericDetailController) {
        assert(row is SimpleDetailItem)
        if let subview = textField,
            let transformer = ValueTransformer(forName: NSValueTransformerName(rawValue: "DateToString")),
            let item = row as? SimpleDetailItem {
            let binding = item.spec.binding
            let options: [NSBindingOption:Any] = [
                .valueTransformer: transformer,
            ]
            
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "date-detail-\(binding)")
            subview.bind(NSBindingName(rawValue: "value"), to:view.index, withKeyPath:"selection.\(binding)", options: options)
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}
