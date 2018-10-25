// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import CoreData

/**
 Protocol providing user interface actions.
 These aren't implemented in the model, but the protocol is defined
 here so that we can implement actions using it.
 */

public protocol BookViewer {
    func reveal(book: Book)
}

/**
 Objects that want to observe changes to books should
 implement this protocol.
 */

public protocol BookChangeObserver: ActionObserver {
    func added(books: [Book])
    func removed(books: [Book])
}

/**
 Common functionality for all book-related actions.
 */

open class BookAction: Action {
    public static let bookKey = "book"

    open class func standardActions() -> [Action] {
        return [
            NewBookAction(identifier: "NewBook"),
            DeleteBookAction(identifier: "DeleteBook"),
            RevealBookAction(identifier: "RevealBook")
        ]
    }
}

/**
 Action to inserts a new book.
 */

public class NewBookAction: BookAction {
    public override func validate(context: ActionContext) -> Bool {
        return (context.info[ActionContext.modelKey] as? NSManagedObjectContext) != nil
    }
    
    public override func perform(context: ActionContext) {
        if let model = context.info[ActionContext.modelKey] as? NSManagedObjectContext {
            let book = Book(context: model)
            context.forObservers { (observer: BookChangeObserver) in
                observer.added(books: [book])
            }
        }
    }
}

/**
 Action that deletes a book.
 */

public class DeleteBookAction: BookAction {
    public override func validate(context: ActionContext) -> Bool {
        guard let selection = context.info[ActionContext.selectionKey] as? [Book] else {
            return false
        }
        
        return selection.count > 0
    }
    
    public override func perform(context: ActionContext) {
        if let selection = context.info[ActionContext.selectionKey] as? [Book] {
            for book in selection {
                book.managedObjectContext?.delete(book)
            }
            context.forObservers { (observer: BookChangeObserver) in
                observer.removed(books: selection)
            }
        }
    }
    
}

/**
 Action that shows a book in the user interface.
 */

class RevealBookAction: BookAction {
    override func validate(context: ActionContext) -> Bool {
        let book = context.info[BookAction.bookKey] as? Book
        return (book != nil) && super.validate(context: context)
    }
    
    override func perform(context: ActionContext) {
        if let book = context.info[BookAction.bookKey] as? Book,
            let viewer = context.info[ActionContext.rootKey] as? BookViewer {
            viewer.reveal(book: book)
        }
    }
}
