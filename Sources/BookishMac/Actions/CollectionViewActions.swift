// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel

class RemoveItemAction: DelegatedAction {
    init(identifier: String) {
        super.init(identifier: identifier) { (context) -> String in
            if let model = context.info[ActionContext.modelKey] as? CollectionDocumentViewModel {
                let identifier = model.mode == .books ? "DeleteBook" : "DeletePerson"
                return identifier
            }
            
            return ""
        }
    }
}

class InsertItemAction: DelegatedAction {
    init(identifier: String) {
        super.init(identifier: identifier) { (context) -> String in
            if let model = context.info[ActionContext.modelKey] as? CollectionDocumentViewModel {
                let identifier = model.mode == .books ? "NewBook" : "NewPerson"
                return identifier
            }
            
            return ""
        }
    }
}
