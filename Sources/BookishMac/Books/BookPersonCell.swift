// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookPersonCell: AnnotatedTableCellView {
    
    @IBOutlet weak var personField: NSTextField!
    var selectedPerson: Person?
    var detailView: BookDetailViewController!

    @IBOutlet weak var personCombo: AnnotatedComboBox!

}

extension BookPersonCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .person)
        let source = view.source
        detailView = view
        if row.placeholder {
            personCombo.stringValue = ""
        } else {
            let relationship = source.person(for: row)
            objectValue = relationship
            if let person = relationship.person, let name = person.name {
                selectedPerson = person
                personCombo.stringValue = name
                personField.stringValue = name
            }
        }

        personCombo.isHidden = !detailView.editing
        personField.isHidden = detailView.editing
        
//        showButtons()
//        self.validateButtons()
    }

    func keyView() -> NSView? {
        return detailView.editing ? personCombo : personField
    }
}

extension BookPersonCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.relationshipKey] = objectValue as? Relationship
    }

}

extension BookPersonCell: NSComboBoxDelegate {
    func comboBoxSelectionDidChange(_ notification: Notification) {
        if let people = detailView?.personList?.arrangedObjects as? [Person] {
            let index = personCombo.indexOfSelectedItem
            if index != -1 {
                let newPerson = people[personCombo.indexOfSelectedItem]
                changePerson(to: newPerson)
            }
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
        if let relationship = objectValue as? Relationship, newPerson != relationship.person {
            let actionManager = application.actionManager
            let info = ActionInfo(sender: self)
            info[PersonAction.relationshipKey] = relationship
            info[PersonAction.personKey] = newPerson
            actionManager.perform(identifier: "ChangeRelationship", info: info)
        }
    }
    
    func changePerson(creating newPersonName: String) {
        if let relationship = objectValue as? Relationship {
            let actionManager = application.actionManager
            let info = ActionInfo(sender: self)
            info[PersonAction.relationshipKey] = relationship
            info[PersonAction.newPersonKey] = newPersonName
            actionManager.perform(identifier: "ChangeRelationship", info: info)
        }
    }
    
}
