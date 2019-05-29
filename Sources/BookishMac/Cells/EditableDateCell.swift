// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class EditableDateCell: AnnotatedTableCellView, ActionContextProvider {
    @IBOutlet weak var infoButton: NSButton!
    var binding: String = ""
    
    override var annotationButtons: [NSButton] {
        return [infoButton]
    }
    
    func provide(context: ActionContext) {
        context.info["object"] = objectValue
        context.info["binding"] = binding
    }
    
}

extension EditableDateCell: DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        assert(row is SimpleDetailItem)
        if let subview = textField, let index = view.indexView,
            let item = row as? SimpleDetailItem {
            binding = item.spec.binding
            let unlocked = view.editing
            subview.isSelectable = unlocked
            subview.isEditable = unlocked
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "date-detail-\(binding)")
            let binder = index.bindSelectionValue(forKey: binding, to: subview, transformer: "DateToString")
            view.binders.append(binder)
            objectValue = index.selection.objects
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}
