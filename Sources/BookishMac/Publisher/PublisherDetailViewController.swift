// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class PublisherDetailViewController: DetailController<Publisher> {
    static let bookViewID = NSUserInterfaceItemIdentifier(rawValue: "book")

    override func rowsForSelection() -> [NSManagedObject] {
        let selected: [Publisher] = selectedItems()
        let (_, common): (Set<Book>, Set<Book>) = items(in: selected, property: "books")
        return common.sorted(by: { $0.name ?? "" < $1.name ?? ""})
    }
    
    override func identifier(for item: NSManagedObject) -> NSUserInterfaceItemIdentifier {
        switch item {
        case is Book:
            return PublisherDetailViewController.bookViewID
        default:
            return super.identifier(for: item)
        }
    }
}
