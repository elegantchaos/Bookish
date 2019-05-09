// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import AppKit

class NavigateBackAction: Action {
    override func validate(context: ActionContext) -> Action.Validation {
        let viewModel = context.info[ActionContext.viewModelKey] as? CollectionViewState
        return Action.Validation(enabled: viewModel?.navigationStack.canGoBack ?? false)
    }
    
    override func perform(context: ActionContext, completed: @escaping Action.Completion) {
        if let window = context[ActionContext.windowKey] as? CollectionWindowController {
            window.navigateBack(completed: completed)
        }
    }
}
