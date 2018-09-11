// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel

class InsertBookAction: Action {
    override func validate(context: ActionContext) -> Bool {
        return (context.info[ActionContext.modelKey] as? CollectionDocumentViewModel) != nil
    }
    
    override func perform(context: ActionContext) {
        if let viewModel = context.info[ActionContext.modelKey] as? CollectionDocumentViewModel {
            let _ = Book(context: viewModel.managedObjectContext)
        }
    }
}
