// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookPersonCell: AnnotatedTableCellView {
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    
    override var annotationButtons: [NSButton] {
        return [addButton, removeButton]
    }
}

extension BookPersonCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: Int, info: DetailDataSource.RowInfo) {
        assert(info.isPerson)
        if let subview = textField {
            let source = view.source
            let personRole = source.person(for: row)
            objectValue = personRole
            subview.bind(NSBindingName(rawValue: "value"), to:personRole, withKeyPath:"person.name", options: [:])
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "person-\(row)")
        }
    }

    func keyView() -> NSView? {
        return textField
    }
}

extension BookPersonCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.roleKey] = objectValue as? PersonRole
    }

}
