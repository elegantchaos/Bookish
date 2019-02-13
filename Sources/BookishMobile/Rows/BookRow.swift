// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions

class BookRow: UITableViewCell, ActionContextProvider, DetailRow {
    @IBOutlet weak var personButton: LinkButton!
    
    var binding: StringBinding?
    var book: Book?

    func setup(row: DetailItem, object: ModelObject) {
        if let item = row as? PersonBookDetailItem, let book = item.book {
            self.book = book
            personButton.setTitle(book.name, for: .normal)
            personButton.linkedObject = book
        }
    }
    
    func provide(context: ActionContext) {
        context.info[BookAction.bookKey] = book
    }
}
