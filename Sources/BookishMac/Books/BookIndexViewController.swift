// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions
import Logger

let bookIndexChannel = Logger("BookIndex")

extension NSArrayController {
    func selectionSummary(singular: String, plural: String) -> String {
        let arranged = (arrangedObjects as! NSArray).count
        let selected = selectionIndexes.count
        let kind = arranged == 1 ? singular : plural
        if selected < 2 {
            return "\(arranged) \(kind)"
        } else {
            return "\(selected) of \(arranged) \(kind)"
        }
    }
}

class BookIndexViewController: IndexController<Book>, BookLifecycleObserver {
    func created(books: [Book]) {
        DispatchQueue.main.async {
            self.select(items: books)
        }
    }
    
    func deleted(books: [Book]) {
        
    }
}
