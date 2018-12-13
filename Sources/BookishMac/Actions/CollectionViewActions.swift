// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import Logger

let modeActionChannel = Logger("ModeActions")

class ModeAction: DelegatedAction {
    class func standardActions() -> [Action] {
        return [
            NewItemAction(identifier: "NewItem"),
            DeleteItemAction(identifier: "DeleteItem"),
        ]
    }

    class func actionIdentifier(for mode: CollectionDocumentViewModel.Mode, action: String, context: ActionContext) -> String {
        let identifier: String
        switch mode {
        case .books: identifier = "\(action)Book"
        case .people: identifier = "\(action)Person"
        case .publishers: identifier = "\(action)Publisher"
        case .series: identifier = "\(action)Series"
        }
        modeActionChannel.debug("Identifier \(identifier) for \(mode) \(context)")
        return identifier
    }
}

class DeleteItemAction: ModeAction {
    init(identifier: String) {
        super.init(identifier: identifier) { (context) -> String in
            guard let model = context.info[ActionContext.viewModelKey] as? CollectionDocumentViewModel else {
                return ""
            }
            
            return ModeAction.actionIdentifier(for: model.mode, action: "Delete", context: context)
        }
    }
}

class NewItemAction: ModeAction {
    init(identifier: String) {
        super.init(identifier: identifier) { (context) -> String in
            guard let model = context.info[ActionContext.viewModelKey] as? CollectionDocumentViewModel else {
                return ""
            }
            
            return ModeAction.actionIdentifier(for: model.mode, action: "New", context: context)
       }
    }
}
