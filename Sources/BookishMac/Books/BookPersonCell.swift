// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookPersonCell: NSTableCellView {
    
    @IBOutlet weak var personField: NSTextField!
    var selectedPerson: Person?
    var detailView: BookDetailViewController?
    
}

extension BookPersonCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .person)
        let source = view.source
        detailView = view
        if row.placeholder {
            
        } else {
            let relationship = source.person(for: row)
            objectValue = relationship
            if let person = relationship.person, let name = person.name {
                personField.stringValue = name
                selectedPerson = person
            }
        }
    }

    func keyView() -> NSView? {
        return personField
    }
}

extension BookPersonCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.relationshipKey] = objectValue as? Relationship
    }

}
