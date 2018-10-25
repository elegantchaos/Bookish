// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import Actions

class PersonBookRow: UITableViewCell, ActionContextProvider {
    @IBOutlet weak var personButton: UIButton!
    
    var binding: StringBinding?
    var book: Book?
    
    func setup(row: Int, book: Book, role: Role) {
        self.book = book
        personButton.setTitle(book.name, for: .normal)
//        binding = StringBinding(for: personButton, property: "value", to: book, path: "name")
//        binding = TextViewBinding(for: detail, to: book, path: "name")
    }

    func provide(context: ActionContext) {
        context.info[BookAction.bookKey] = book
    }
}
