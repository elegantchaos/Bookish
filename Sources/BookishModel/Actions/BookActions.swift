// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import CoreData

public protocol BookChangeObserver: ActionObserver {
    func added(books: [Book])
    func removed(books: [Book])
}

open class BookAction: Action {
    public static let bookKey = "book"

    open class func standardActions() -> [Action] {
        return [
            InsertBookAction(identifier: "InsertBook"),
            RemoveBookAction(identifier: "RemoveBook"),
        ]
    }
}

public class InsertBookAction: BookAction {
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

public class RemoveBookAction: BookAction {
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


