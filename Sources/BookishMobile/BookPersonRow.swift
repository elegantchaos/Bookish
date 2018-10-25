// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import Actions

class BookPersonRow: BookDetailRow {
    @IBOutlet var personButton: UIButton!
    var role: PersonRole!
    
    override func setup(row: Int, book: Book, source: DetailDataSource) {
        assert(source.info(for: row).isPerson)
        role = source.person(for: row)
        label.text = role.role?.name
        personButton.setTitle(role.person?.name, for: .normal)
    }
}

extension BookPersonRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.roleKey] = role
    }
}
