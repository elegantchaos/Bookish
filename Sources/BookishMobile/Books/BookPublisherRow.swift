// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import Actions
import BookishModel

class BookPublisherRow: BookDetailRow {
    @IBOutlet var publisherButton: UIButton!
    var publisher: Publisher!

    override func setup(row: DetailDataSource.RowInfo, book: Book, source: DetailDataSource) {
        assert(row.category == .publisher)
        publisher = source.publisher(for: row)
        label.text = publisher.name
        publisherButton.setTitle(publisher.name, for: .normal)
   }
}

extension BookPublisherRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PublisherAction.newPublisherKey] = publisher
    }
}

