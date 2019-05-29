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
    var observer: NSKeyValueObservation?
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
            updateValue()
            view.addDoubleClickUnlock(to: subview)
            subview.placeholderString = "detail.\(binding).placeholder".localized
        }
    }
    
    func updateValue() {

        if let subview = textField, let spec = objectValue as? DetailSpec {
            detailView.indexView.copySelectionValue(forKey: spec.binding, to: subview)
            let value = detailView.indexView.selectionValue(forKey: spec.binding)
            switch value {
            case .value(value: let value):
                asNumber = ((value as? NSNumber) != nil)
            default:
                asNumber = false
            }
        }
    }

    func keyView() -> NSView? {
        return textField
    }
    
    override func prepareForReuse() {
        observer = nil
        super.prepareForReuse()
    }
}

extension DetailCell {
    override func controlTextDidEndEditing(_ obj: Notification) {
        if detailView.editing, let subview = textField, let detail = objectValue as? DetailSpec {
            let value: Any
            let changed: Bool
            if asNumber {
                let number = subview.doubleValue
                changed = number != (originalValue as NSString).doubleValue
                value = number
            } else {
                let string = subview.stringValue
                changed = string != originalValue
                value = string
            }
            
            if changed {
                ChangeValueAction.send("ChangeValue", from: self, manager: application.actionManager, property: detail.binding, value: value)
            }

        }
        super.controlTextDidEndEditing(obj)
    }
}
