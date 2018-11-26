// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import Actions

class BookPersonRow: BookDetailRow {
    @IBOutlet var personButton: UIButton!
    var relationship: Relationship!
    
    override func setup(row: Int, book: Book, source: DetailDataSource) {
        assert(source.info(for: row).isPerson)
        relationship = source.person(for: row)
        label.text = relationship.role?.name
        personButton.setTitle(relationship.person?.name, for: .normal)
    }
}

extension BookPersonRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.relationshipKey] = relationship
    }
}
