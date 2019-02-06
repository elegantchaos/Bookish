// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import Actions
import UIKit

class ChooseTarget {
    let row: BookPersonRow
    
    init(row: BookPersonRow) {
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

class BookPersonRow: BookDetailRow {
    
    var relationship: Relationship?
    var person: Person?
    var role: Role?
    
    @IBOutlet var personButton: UIButton!
    @IBOutlet weak var roleButton: UIButton!
    @IBOutlet weak var personField: UITextField!
    @IBOutlet weak var choosePersonButton: UIButton!
    
    override func setupContent(row: DetailItem, book: Book) {
        assert(row is PersonDetailItem)
        if row.placeholder {
            role = Role.named(Role.StandardNames.author, in: book.managedObjectContext!)
        } else {
            relationship = source.relationship(for: row)
            role = relationship?.role
            person = relationship?.person
        }
        
        setupPerson()
        setupRole()
    }
    
    func setupPerson() {
        let personName = person?.name ?? ""
        personField.font = application.viewModel.detailFont
        personField.text = personName
        personButton.setTitle(personName, font: application.viewModel.detailFont)
        personButton.isHidden = source.editing
        choosePersonButton.isHidden = !source.editing
        personField.isHidden = !source.editing
    }
    
    func setupRole() {
        let roleName = role?.label ?? "role"
        label.text = roleName
        label.isHidden = source.editing
        roleButton.setTitle(roleName, font: application.viewModel.detailFont)
        roleButton.isHidden = !source.editing
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

extension BookPersonRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.relationshipKey] = relationship
        if source.editing {
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
