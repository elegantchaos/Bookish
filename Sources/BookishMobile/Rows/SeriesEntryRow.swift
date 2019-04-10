// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/04/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import UIKit

class SeriesEntryRow: BookDetailRow {
    
    var entry: SeriesEntry?
    
    @IBOutlet var bookButton: LinkButton!
    
    override func setupContent(row: DetailItem, object: ModelObject) {
        if let item = row as? SeriesEntryDetailItem {
            if item.placeholder {
                entry = nil
            } else {
                entry = item.entry
            }
            
            setupEntry()
        }
    }
    
    func setupEntry() {
        let bookName = entry?.book?.name ?? ""
        bookButton.setTitle(bookName, font: application.viewState.detailFont)
        bookButton.linkedObject = entry?.book
    }
}

extension SeriesEntryRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[BookAction.bookKey] = entry?.book
    }
}
