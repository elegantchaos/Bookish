// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class TransformedCell: NSTableCellView {
    @IBOutlet weak var infoButton: NSButton!
    
    var transformerName: String { return "" }
}

extension TransformedCell: DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        assert(row is SimpleDetailItem)
        if let subview = textField, let index = view.indexView,
            let item = row as? SimpleDetailItem {
            let binding = item.spec.binding
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "detail-\(binding)")
            let binder = index.bindSelectionValue(forKey: binding, to: subview, transformer: transformerName)
            view.binders.append(binder)
            view.addDoubleClickUnlock(to: subview)
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}
