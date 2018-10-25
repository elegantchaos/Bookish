// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookDateCell: AnnotatedTableCellView, ActionContextProvider {
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

extension BookDateCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: Int, info: DetailDataSource.RowInfo) {
        assert(!info.isPerson)
        if let subview = textField,
            let index = view.indexView.indexArray,
            let transformer = ValueTransformer(forName: NSValueTransformerName(rawValue: "DateToString")) {
            let detail = view.source.details(for: row)
            let unlocked = detail.editable
            let options: [NSBindingOption:Any] = [
                .valueTransformer: transformer,
                .conditionallySetsEditable: unlocked
            ]
            
            subview.isSelectable = unlocked
            subview.isEditable = unlocked
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "date-detail-\(detail.binding)")
            subview.bind(NSBindingName(rawValue: "value"), to:index, withKeyPath:"selection.\(detail.binding)", options: options)

            objectValue = index.selection as? NSObject
            binding = detail.binding
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
}
