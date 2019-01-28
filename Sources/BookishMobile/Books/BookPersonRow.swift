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
    @IBOutlet weak var roleButton: UIButton!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var personField: UITextField!
    
    override func setup(row: DetailDataSource.RowInfo, book: Book, source: DetailDataSource) {
        assert(row.category == .person)
        if row.placeholder {
            roleButton.setTitle("role >", for: .normal)
            personField.placeholder = "person name"
        } else {
            relationship = source.relationship(for: row)
            let role = relationship?.role?.label ?? "role"
            let person = relationship?.person?.name ?? ""
            if source.editing {
                roleButton.setTitle("\(role) >", for: .normal)
                personField.text = person
            } else {
                roleLabel.text = role
                personButton.setTitle(person, for: .normal)
            }
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
    }
}
