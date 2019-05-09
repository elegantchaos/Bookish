// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import AppKit

class NavigateBackAction: Action {
    override func perform(context: ActionContext, completed: @escaping Action.Completion) {
        print("navigate back")
        if let viewModel = context.info[ActionContext.viewModelKey] as? CollectionViewState {
            print("stack is \(viewModel.navigationStack)")
        }
        completed()
    }
}
