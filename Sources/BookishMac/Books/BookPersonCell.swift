// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookPersonCell: AnnotatedTableCellView {
    
    @IBOutlet weak var personField: NSTextField!
//    var selectedPerson: Person?
    var selectedRole: Role? {
        if let table = detailView.detailsTable, let roles = detailView.roleList.arrangedObjects as? [Role] {
            let row = table.row(for: self)
            if row != -1, let heading = table.view(atColumn: 1, row: row, makeIfNecessary: false) as? BookPersonHeadingCell {
                return roles[heading.rolePopup.indexOfSelectedItem]
            }
        }
        return nil
    }

    var detailView: BookDetailViewController!

    @IBOutlet weak var personCombo: AnnotatedComboBox!

}

extension BookPersonCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: DetailDataSource.RowInfo) {
//        if let heading = view.detailsTable.view(atColumn: 1, row: row.absolute, makeIfNecessary: false) as? BookPersonHeadingCell {
//            if let role = heading.rolePopup.selectedItem?.representedObject as? Role {
//                selectedRole = role
//            }
//        }
        
        assert(row.category == .person)
        let source = view.source
        detailView = view
        if row.placeholder {
            personCombo.stringValue = ""
        } else {
            let relationship = source.person(for: row)
            objectValue = relationship
            if let person = relationship.person, let name = person.name {
//                selectedPerson = person
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
            if let newPerson = Person.named(newName, in: context) {
                changePerson(to: newPerson)
            } else {
                changePerson(creating: newName)
            }
        }
    }
    
    func changePerson(to newPerson: Person) {
        let relationship = objectValue as? Relationship
        if newPerson != relationship?.person {
            let actionManager = application.actionManager
            let info = makeInfo()
            info[PersonAction.personKey] = newPerson
            actionManager.perform(identifier: "ChangeRelationship", info: info)
        }
    }
    
    func changePerson(creating newPersonName: String) {
        let actionManager = application.actionManager
        let info = makeInfo()
        info[PersonAction.newPersonKey] = newPersonName
        actionManager.perform(identifier: "ChangeRelationship", info: info)
    }
    
    func makeInfo() -> ActionInfo {
        let info = ActionInfo(sender: self)
        
        let relationship = objectValue as? Relationship
        if let relationship = relationship {
            info[PersonAction.relationshipKey] = relationship
        }
        
        if let role = selectedRole {
            info[PersonAction.roleKey] = role
        }
        
        return info
    }
}
