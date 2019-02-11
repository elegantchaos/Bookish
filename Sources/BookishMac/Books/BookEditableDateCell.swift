// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookEditableDateCell: AnnotatedTableCellView, ActionContextProvider {
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

extension BookEditableDateCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: DetailItem) {
        assert(row is SimpleDetailItem)
        if let subview = textField,
            let transformer = ValueTransformer(forName: NSValueTransformerName(rawValue: "DateToString")),
            let item = row as? SimpleDetailItem {
            binding = item.spec.binding
            let unlocked = view.editing
            let options: [NSBindingOption:Any] = [
                .valueTransformer: transformer,
                .conditionallySetsEditable: unlocked
            ]
            
            subview.isSelectable = unlocked
            subview.isEditable = unlocked
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "date-detail-\(binding)")
            subview.bind(NSBindingName(rawValue: "value"), to:view.index, withKeyPath:"selection.\(binding)", options: options)
            
            objectValue = view.index.selection as? NSObject
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}
