// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import Actions
import UIKit

class BookPersonRow: BookDetailRow {
    @IBOutlet var personButton: UIButton!
    var relationship: Relationship?
    var person: Person?
    var role: Role?
    var source: DetailDataSource!
    
    @IBOutlet weak var roleButton: UIButton!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var personField: UITextField!
    
    override func setup(row: DetailDataSource.RowInfo, book: Book, source: DetailDataSource) {
        assert(row.category == .person)
        self.source = source
        if row.placeholder {
            role = Role.named(Role.StandardNames.author, in: book.managedObjectContext!)
        } else {
            relationship = source.relationship(for: row)
            role = relationship?.role
            person = relationship?.person
        }
        
        let roleName = role?.label ?? "role"
        let personName = person?.name ?? ""
        if source.editing {
            roleButton.setTitle("\(roleName) >", for: .normal)
            personField.text = personName
        } else {
            roleLabel.text = roleName
            personButton.setTitle(personName, for: .normal)
        }
        
        roleLabel.isHidden = source.editing
        personButton.isHidden = source.editing
        
        roleButton.isHidden = !source.editing
        personField.isHidden = !source.editing
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
