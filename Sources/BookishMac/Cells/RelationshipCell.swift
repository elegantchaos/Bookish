// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class RelationshipCell: NSTableCellView {
    
    @IBOutlet weak var personField: NSTextField!
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        print("willMoveTo \(newWindow)")
        super.viewWillMove(toWindow: newWindow)
    }
    
    var roleCell: RoleCell? {
        if let table = detailView.detailsTable {
            let row = table.row(for: self)
            if row != -1 {
                return table.view(atColumn: 1, row: row, makeIfNecessary: false) as? RoleCell
            }
        }
        return nil
    }
    
    var selectedRole: Role? {
        if let heading = roleCell, let roles = detailView.roleList.arrangedObjects as? [Role] {
            return roles[heading.rolePopup.indexOfSelectedItem]
        }
        return nil
    }

    var detailView: DetailController!

    @IBOutlet weak var personCombo: AnnotatedComboBox!

}

extension RelationshipCell: DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        assert(row is RelationshipDetailItem)
        
        let clickRecogniser = NSClickGestureRecognizer(target: self, action: #selector(personClicked(_:)))
        personField.addGestureRecognizer(clickRecogniser)

        detailView = view
        if row.placeholder {
            personCombo.stringValue = ""
            detailChannel.debug("setup as a placeholder")
        } else if let item = row as? RelationshipDetailItem, let relationship = item.relationship {
            objectValue = relationship
            if let person = relationship.person, let name = person.name {
                if !detailView.editing {
                    personField.stringValue = name
                } else if let index = detailView.index(of: person) {
                    detailChannel.debug("setup with selection \(index) \(name)")
                    personCombo.selectItem(at: index)
                } else {
                    detailChannel.debug("setup with unknown name \(name)")
                    personCombo.stringValue = name
                }
            }
        }

        personCombo.isHidden = !detailView.editing
        personField.isHidden = detailView.editing
    }

    func keyView() -> NSView? {
        return detailView.editing ? personCombo : personField
    }
    
    @IBAction func personClicked(_ sender: Any) {
        application.actionManager.perform(identifier: "RevealPerson", info: ActionInfo(sender: self))
    }
}

extension RelationshipCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.relationshipKey] = objectValue as? Relationship
        context.info.addObserver(self)
        
        if detailView.editing {
            let person = detailView.person(at: personCombo.indexOfSelectedItem)
            context.info[PersonAction.personKey] = person ?? personCombo.stringValue
            context[PersonAction.roleKey] = selectedRole
        }
    }
}

extension RelationshipCell: BookChangeObserver {
    func replaced(relationship: Relationship, with: Relationship) {
        objectValue = with
        roleCell?.objectValue = with
    }
    
    func added(relationship: Relationship) {
        objectValue = relationship
        roleCell?.objectValue = relationship
    }
}
