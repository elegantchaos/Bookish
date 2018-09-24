// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel

class ConditionalAction: Action {
    typealias ConditionalIdentifier = (ActionContext) -> String
    let conditionalIdentifier: ConditionalIdentifier
    
    init(identifier: String, condition: @escaping ConditionalIdentifier) {
        self.conditionalIdentifier = condition
        super.init(identifier: identifier)
    }

    override func validate(context: ActionContext) -> Bool {
        let manager = context.manager
        let identifier = conditionalIdentifier(context)
        return manager.validate(identifier: identifier, item: context.sender)
    }

    override func perform(context: ActionContext) {
        let manager = context.manager
        let identifier = conditionalIdentifier(context)
        manager.perform(identifier: identifier, sender: context.sender)
    }
}

class RemoveItemAction: ConditionalAction {
    init(identifier: String) {
        super.init(identifier: identifier) { (context) -> String in
            if let model = context.info[ActionContext.modelKey] as? CollectionDocumentViewModel {
                let identifier = model.mode == .books ? "RemoveBook" : "DeletePerson"
                return identifier
            }
            
            return ""
        }
    }
}

class InsertItemAction: ConditionalAction {
    init(identifier: String) {
        super.init(identifier: identifier) { (context) -> String in
            if let model = context.info[ActionContext.modelKey] as? CollectionDocumentViewModel {
                let identifier = model.mode == .books ? "InsertBook" : "NewPerson"
                return identifier
            }
            
            return ""
        }
    }
}
