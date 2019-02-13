// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import Actions
import BookishModel

class PublisherRow: BookDetailRow {
    @IBOutlet var publisherButton: LinkButton!
    var publisher: Publisher!
    
    override func setupContent(row: DetailItem, book: Book) {
        if let item = row as? PublisherDetailItem {
            if row.placeholder {
                
            } else {
                publisher = item.publisher
                publisherButton.setTitle(publisher.name, font: application.viewModel.detailFont)
                publisherButton.linkedObject = publisher
            }
        }
    }
}

extension PublisherRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PublisherAction.newPublisherKey] = publisher
    }
}

