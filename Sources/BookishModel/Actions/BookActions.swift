// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel

class BookAction: Action {
    static let bookKey = "book"

    class func standardActions() -> [Action] {
        return [
            InsertBookAction(identifier: "InsertBook"),
            RemoveBookAction(identifier: "RemoveBook"),
            RevealBookAction(identifier: "RevealBook")
        ]
    }
}

class InsertBookAction: BookAction {
    override func validate(context: ActionContext) -> Bool {
        return (context.info[ActionContext.modelKey] as? CollectionDocumentViewModel) != nil
    }
    
    override func perform(context: ActionContext) {
        if let viewModel = context.info[ActionContext.modelKey] as? CollectionDocumentViewModel {
            let _ = Book(context: viewModel.managedObjectContext)
        }
    }
}

class RemoveBookAction: BookAction {
    override func validate(context: ActionContext) -> Bool {
        guard let selection = context.info[ActionContext.selectionKey] as? [Book] else {
            return false
        }
        
        return selection.count > 0
    }
    
    override func perform(context: ActionContext) {
        if let selection = context.info[ActionContext.selectionKey] as? [Book] {
            for book in selection {
                book.managedObjectContext?.delete(book)
            }
        }
    }
    
}

class RevealBookAction: BookAction {
    override func validate(context: ActionContext) -> Bool {
        return (context.info[BookAction.bookKey] as? Book != nil) && super.validate(context: context)
    }
    
    override func perform(context: ActionContext) {
        if let book = context.info[BookAction.bookKey] as? Book,
            let window = context.info[ActionContext.windowKey] as? CollectionWindowController {
            window.reveal(book: book)
        }
    }
}



