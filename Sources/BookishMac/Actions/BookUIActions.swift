// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

class BookUIAction: BookAction {

    class func standardActions() -> [Action] {
        return [
            RevealBookAction(identifier: "RevealBook")
        ]
    }

    class RevealBookAction: BookUIAction {
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
    

}
