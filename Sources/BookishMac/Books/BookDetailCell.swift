// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

fileprivate var detailBindingContext: Int = 0

class BookDetailCell: NSTableCellView, BookDetailTableCell {
    var detailView: BookDetailViewController?
    var observer: NSKeyValueObservation?
    var asNumber = false
    
    func setup(for view: BookDetailViewController, row: Int, isPerson: Bool) {
        assert(!isPerson)
        
        detailView = view
        if let subview = textField, let index = view.indexView.indexArray {
            let detail = view.source.details(for: row)
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "detail-\(detail.binding)")
            subview.isEditable = view.editing
            objectValue = detail
            index.addObserver(self, forKeyPath: "selection.\(detail.binding)", options: [.initial], context: &detailBindingContext)
        }
    }
    
    func updateValue() {
        if let subview = textField, let view = detailView, let index = view.indexView.indexArray, let selection = index.selection as? NSObject, let detail = objectValue as? DetailSpec {
            let selection = selection.value(forKey: detail.binding) as? NSObject
            if selection === NSMultipleValuesMarker {
                subview.placeholderString = "Multiple Values"
            } else {
                subview.objectValue = selection
                asNumber = selection?.isKind(of: NSNumber.self) ?? false
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &detailBindingContext {
            updateValue()
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
    
    override func prepareForReuse() {
        observer = nil
    }
}

extension BookDetailCell: NSControlTextEditingDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        if let subview = textField, let detail = objectValue as? DetailSpec {
            let actionManager = application.actionManager
            let info = ActionInfo(sender: self)
            info[ChangeValueAction.propertyKey] = detail.binding
            let value: Any = asNumber ? subview.doubleValue : subview.stringValue
            info[ChangeValueAction.valueKey] = value
            actionManager.perform(identifier: "ChangeValue", info: info)
        }
    }
}
