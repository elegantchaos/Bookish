// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import Logger

let itemActionChannel = Logger("ItemAction")

extension ActionContext {
    var viewModel : CollectionViewState? {
        return info[ActionContext.viewModelKey] as? CollectionViewState
    }
}

class ItemAction: DelegatedAction {
    class func standardActions() -> [Action] {
        return [
            NewItemAction(),
            DeleteItemAction(),
            RevealItemAction()
        ]
    }
    
    class func actionIdentifier(for mode: CollectionViewState.Mode, action: String, context: ActionContext) -> String {
        let identifier = "\(action)\(mode.singularName())"
        itemActionChannel.debug("Identifier \(identifier) for \(mode) \(context)")
        return identifier
    }
    
    func viewModel(for context: ActionContext) -> CollectionViewState? {
        return context.info[ActionContext.viewModelKey] as? CollectionViewState
    }
}

class DeleteItemAction: ItemAction {
    init(identifier: String? = nil) {
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
            result = Action.Validation(enabled: result.enabled, visible: result.visible, name: "Delete \(model.mode.singularName())")
        }
        
        return result
    }
}

class NewItemAction: ItemAction {
    init(identifier: String? = nil) {
        super.init(identifier: identifier) { (context) -> String in
            guard let model = context.viewModel else {
                return ""
            }
            
            return ItemAction.actionIdentifier(for: model.mode, action: "New", context: context)
       }
    }
}

class RevealItemAction: DelegatedAction {
    init(identifier: String? = nil) {
        super.init(identifier: identifier) { (context) -> String in
            if context[PublisherAction.publisherKey] != nil {
                return "RevealPublisher"
            } else if context[SeriesAction.seriesKey] != nil {
                return "RevealSeries"
            } else if context[BookAction.bookKey] != nil {
                return "RevealBook"
            } else {
                return "RevealPerson"
            }
        }
    }
}
