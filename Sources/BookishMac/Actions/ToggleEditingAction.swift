// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions

protocol EditableView {
    var editing: Bool { get }
    func toggleEditing()
}

class ToggleEditingAction: Action {
    static let editableKey = "editable"
    
    override func validate(context: ActionContext) -> Validation {
        if let _ = context[ToggleEditingAction.editableKey] as? EditableView {
            return Action.Validation()
        }
        
        return Validation(visible: false)
    }
    
    override func perform(context: ActionContext) {
        if let view = context[ToggleEditingAction.editableKey] as? EditableView {
            view.toggleEditing()
        }
    }
}
