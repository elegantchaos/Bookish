// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class DateCell: NSTableCellView {
    @IBOutlet weak var infoButton: NSButton!
    
    var transformerName: String { return "DateToString" }
}

extension DateCell: DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        assert(row is SimpleDetailItem)
        if let subview = textField,
            let transformer = ValueTransformer(forName: NSValueTransformerName(rawValue: transformerName)),
            let item = row as? SimpleDetailItem {
            let binding = item.spec.binding
            let options: [NSBindingOption:Any] = [
                .valueTransformer: transformer,
            ]
            
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "date-detail-\(binding)")
            subview.bind(NSBindingName(rawValue: "value"), to:view.index, withKeyPath:"selection.\(binding)", options: options)
            view.addDoubleClickUnlock(to: subview)
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}
