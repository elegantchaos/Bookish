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
    @IBOutlet weak var personCombo: NSComboBoxCell!
    
    var selectedPerson: Person?
    var detailView: BookDetailViewController?
    
    override var annotationButtons: [NSButton] {
        return [addButton, removeButton]
    }
}

extension BookPersonCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: Int, info: DetailDataSource.RowInfo) {
        assert(info.isPerson)
        let source = view.source
        detailView = view
        let personRole = source.person(for: row)
        objectValue = personRole
        if let person = personRole.person, let name = person.name {
            selectedPerson = person
            personCombo.stringValue = name
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
        if let people = detailView?.personList?.arrangedObjects as? [Person] {
            let newPerson = people[personCombo.indexOfSelectedItem]
            changePerson(to: newPerson)
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        super.controlTextDidEndEditing(obj)
        if let context = detailView?.cvm.managedObjectContext {
            let newName = personCombo.stringValue
            if let newPerson = Person.person(named: newName, context: context) {
                changePerson(to: newPerson)
            } else {
                changePerson(creating: newName)
            }
        }
    }

    func changePerson(to newPerson: Person) {
        if let personRole = objectValue as? PersonRole, newPerson != personRole.person {
            let actionManager = application.actionManager
            actionManager.perform(identifier: "ChangeRolePerson", sender: self, info: [PersonAction.roleKey:personRole, PersonAction.personKey:newPerson])
        }
    }

    func changePerson(creating newPersonName: String) {
        if let personRole = objectValue as? PersonRole {
            let actionManager = application.actionManager
            actionManager.perform(identifier: "ChangeRolePerson", sender: self, info: [PersonAction.roleKey:personRole, PersonAction.newPersonKey:newPersonName])
        }
    }

}
