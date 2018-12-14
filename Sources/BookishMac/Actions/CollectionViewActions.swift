// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import Logger

let modeActionChannel = Logger("ModeActions")

extension ActionContext {
    var viewModel : CollectionDocumentViewModel? {
        return info[ActionContext.viewModelKey] as? CollectionDocumentViewModel
    }
}

class ModeAction: DelegatedAction {
    class func standardActions() -> [Action] {
        return [
            NewItemAction(identifier: "NewItem"),
            DeleteItemAction(identifier: "DeleteItem"),
        ]
    }
    
    class func actionIdentifier(for mode: CollectionDocumentViewModel.Mode, action: String, context: ActionContext) -> String {
        let identifier = "\(action)\(mode.singluarName())"
        modeActionChannel.debug("Identifier \(identifier) for \(mode) \(context)")
        return identifier
    }
    
    func viewModel(for context: ActionContext) -> CollectionDocumentViewModel? {
        return context.info[ActionContext.viewModelKey] as? CollectionDocumentViewModel
    }
}

class DeleteItemAction: ModeAction {
    init(identifier: String) {
        super.init(identifier: identifier) { (context) -> String in
            guard let model = context.viewModel else {
                return ""
            }
            
            return ModeAction.actionIdentifier(for: model.mode, action: "Delete", context: context)
        }
    }
    
    override func validate(context: ActionContext) -> Action.Validation {
        var result: Action.Validation = super.validate(context: context)
        
        if let model = context.viewModel {
            result = Action.Validation(enabled: result.enabled, visible: result.visible, name: "Delete \(model.mode.singluarName())")
        }
        
        return result
    }
}

class NewItemAction: ModeAction {
    init(identifier: String) {
        super.init(identifier: identifier) { (context) -> String in
            guard let model = context.viewModel else {
                return ""
            }
            
            return ModeAction.actionIdentifier(for: model.mode, action: "New", context: context)
       }
    }
}
