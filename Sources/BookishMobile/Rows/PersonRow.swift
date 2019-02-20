// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import Actions
import UIKit

class ChooseTarget {
    let row: PersonRow
    
    init(row: PersonRow) {
        self.row = row
    }
}

class ChooseRoleTarget: ChooseTarget, ChooseItemTarget {
    var value: Role? {
        return row.role
    }
    
    func choose(value: Role) {
        row.changeRole(to: value)
    }
    
    typealias EntityType = Role
}

class ChoosePersonTarget: ChooseTarget, ChooseItemTarget {
    var value: Person? {
        return row.person
    }
    
    func choose(value: Person) {
        row.changePerson(to: value)
    }
    
    typealias EntityType = Person
}

class PersonRow: BookDetailRow {
    
    var relationship: Relationship?
    var person: Person?
    var role: Role?
    
    @IBOutlet var personButton: LinkButton!
    @IBOutlet weak var roleButton: UIButton!
    @IBOutlet weak var personField: UITextField!
    @IBOutlet weak var choosePersonButton: UIButton!
    
    override func setupContent(row: DetailItem, object: ModelObject) {
        if let item = row as? PersonDetailItem {
            if item.placeholder {
                role = Role.named(Role.StandardName.author, in: object.managedObjectContext!)
            } else {
                relationship = item.relationship
                role = relationship?.role
                person = relationship?.person
            }
            
            setupPerson()
            setupRole()
        }
    }
    
    func setupPerson() {
        let personName = person?.name ?? ""
        personField.font = application.viewState.detailFont
        personField.text = personName
        personButton.setTitle(personName, font: application.viewState.detailFont)
        personButton.linkedObject = person
        let editing = info.source.isEditing
        personButton.isHidden = editing
        choosePersonButton.isHidden = !editing
        personField.isHidden = !editing
    }
    
    func setupRole() {
        let roleName = role?.label ?? "role"
        label.text = roleName
        
        let editing = info.source.isEditing
        label.isHidden = editing
        roleButton.setTitle(roleName, font: application.viewState.detailFont)
        roleButton.isHidden = !editing
    }
    
    func changeRole(to role: Role) {
        self.role = role
        setupRole()
        application.actionManager.perform(identifier: "ChangeRelationship", info: ActionInfo(sender: self))
    }

    func changePerson(to person: Person) {
        self.person = person
        setupPerson()
        application.actionManager.perform(identifier: "ChangeRelationship", info: ActionInfo(sender: self))
    }
}

extension PersonRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.relationshipKey] = relationship
        if info.source.isEditing {
            if let person = person, person.name == personField.text {
                context[PersonAction.personKey] = person
            } else if let name = personField.text, !name.isEmpty {
                context[PersonAction.personKey] = name
            }
            
            if let role = role {
                context[PersonAction.roleKey] = role
            }
        }
    }
}
