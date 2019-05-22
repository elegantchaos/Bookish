// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions

class FilterActions: Action {
    static let filterableKey = "filterable"
    
    class func standardActions() -> [Action] {
        return [
            ClearFilterAction()
        ]
    }

}

protocol FilterableView {
    func clearFilter()
}

class ClearFilterAction: Action {
    override func validate(context: ActionContext) -> Bool {
        let filterable = context[FilterActions.filterableKey] as? FilterableView
        return (filterable != nil) && super.validate(context: context)
    }
    
    override func perform(context: ActionContext) {
        if let filterable = context[FilterActions.filterableKey] as? FilterableView {
            filterable.clearFilter()
        }
    }
}
