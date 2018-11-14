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
    @IBOutlet weak var personPopup: NSPopUpButton!
    @IBOutlet weak var personCombo: NSComboBoxCell!
    
    override var annotationButtons: [NSButton] {
        return [addButton, removeButton]
    }
}

extension BookPersonCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: Int, info: DetailDataSource.RowInfo) {
        assert(info.isPerson)
        if let subview = textField, let transformer = ValueTransformer(forName: AuthorSelectionTransformer.name) {
            let source = view.source
            let personRole = source.person(for: row)
            objectValue = personRole
            let options: [NSBindingOption:Any] = [
                .valueTransformer: transformer,
                ]
            subview.bind(NSBindingName(rawValue: "value"), to:personRole, withKeyPath:"self", options: options)
            subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "person-\(row)")
            
            if let person = personRole.person, let name = person.name, let index = view.personList.firstIndex(of: person) {
                personPopup.menu = view.personMenu
                personPopup.selectItem(at: index)
                
                personCombo.stringValue = name
            }
            
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

extension BookPersonCell: NSComboBoxDelegate {
    func comboBoxSelectionDidChange(_ notification: Notification) {
        print("did change \(notification)")
    }
    
    func comboBoxSelectionIsChanging(_ notification: Notification) {
        print("is changing \(notification)")
    }
    
    func controlTextDidChange(_ obj: Notification) {
        print(obj)
    }
}
