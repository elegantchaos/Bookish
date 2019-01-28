// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import Actions
import UIKit

class BookIndexController: IndexController<BookDetailController, Book> {
     override func provide(context: ActionContext) {
        context.info.addObserver(self)
        super.provide(context: context)
    }    
    
    override func configureCell(_ cell: UITableViewCell, with book: Book) {
        cell.textLabel!.text = book.name
    }
}

extension BookIndexController: BookChangeObserver {
    func added(relationship: Relationship) {
    }
    
    func removed(relationship: Relationship) {
    }
    
    func added(series: Series) {
    }
    
    func removed(series: Series) {
    }
    
    func added(publisher: Publisher) {
    }
    
    func removed(publisher: Publisher) {
    }
    
    
    func added(books: [Book]) {
        print("added")
    }
    
    func removed(books: [Book]) {
        print("removed")
    }
}
