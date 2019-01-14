// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import Logger

let itemActionChannel = Logger("ItemAction")

extension ActionContext {
    var viewModel : CollectionViewModel? {
        return info[ActionContext.viewModelKey] as? CollectionViewModel
    }
}

class ItemAction: DelegatedAction {
    class func standardActions() -> [Action] {
        return [
            NewItemAction(identifier: "NewItem"),
            DeleteItemAction(identifier: "DeleteItem"),
        ]
    }
    
    class func actionIdentifier(for mode: CollectionViewModel.Mode, action: String, context: ActionContext) -> String {
        let identifier = "\(action)\(mode.singluarName())"
        itemActionChannel.debug("Identifier \(identifier) for \(mode) \(context)")
        return identifier
    }
    
    func viewModel(for context: ActionContext) -> CollectionViewModel? {
        return context.info[ActionContext.viewModelKey] as? CollectionViewModel
    }
}

class DeleteItemAction: ItemAction {
    init(identifier: String) {
        super.init(identifier: identifier) { (context) -> String in
            guard let model = context.viewModel else {
                return ""
            }
            
            return ItemAction.actionIdentifier(for: model.mode, action: "Delete", context: context)
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

class NewItemAction: ItemAction {
    init(identifier: String) {
        super.init(identifier: identifier) { (context) -> String in
            guard let model = context.viewModel else {
                return ""
            }
            
            return ItemAction.actionIdentifier(for: model.mode, action: "New", context: context)
       }
    }
}
