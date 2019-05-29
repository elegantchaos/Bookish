// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

fileprivate var detailBindingContext: Int = 0

class DetailCell: AnnotatedTableCellView, DetailTableCell {
    var detailView: DetailController!
    var asNumber = false
    var originalValue = ""
    
    func setup(for row: DetailItem, of view: DetailController) {
        assert(row is SimpleDetailItem)
        
        detailView = view

        if let item = row as? SimpleDetailItem, let subview = textField {
            var font = detailView.cvm.detailFont
            if item.spec.isDebug, let smaller = NSFont(descriptor: font.fontDescriptor, size: font.pointSize - 2) {
                font = smaller
                subview.textColor = NSColor(named: "Bookish Label Text")
            }
            subview.font = font

            let binding = item.spec.binding
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "detail-\(binding)")
            subview.isEditable = view.editing
            objectValue = item.spec
            view.addDoubleClickUnlock(to: subview)
            let binder = detailView.indexView.bindSelectionValue(forKey: binding, to: subview)
            detailView.binders.append(binder)
        }
    }

    func keyView() -> NSView? {
        return textField
    }
}
