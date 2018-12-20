// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions
import Logger

let bookIndexChannel = Logger("BookIndex")

class BookIndexViewController: IndexController<Book>, BookLifecycleObserver {
    func created(books: [Book]) {
        DispatchQueue.main.async {
            self.select(items: books)
        }
    }
    
    func deleted(books: [Book]) {
        
    }
}
