// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookEditablePersonCell: AnnotatedTableCellView {
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    @IBOutlet weak var personCombo: NSComboBoxCell!
    
    var selectedPerson: Person?
    var detailView: BookDetailViewController?
    
    override var annotationButtons: [NSButton] {
        return [addButton, removeButton]
    }
}

extension BookEditablePersonCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .person)
        let source = view.source
        detailView = view
        if row.placeholder {
            
        } else {
            let relationship = source.person(for: row)
            objectValue = relationship
            if let person = relationship.person, let name = person.name {
                selectedPerson = person
                personCombo.stringValue = name
            }
        }
        showButtons()
        self.validateButtons()
    }
    
    func keyView() -> NSView? {
        return textField
    }
}

extension BookEditablePersonCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.relationshipKey] = objectValue as? Relationship
    }
    
}

extension BookEditablePersonCell: NSComboBoxDelegate {
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
