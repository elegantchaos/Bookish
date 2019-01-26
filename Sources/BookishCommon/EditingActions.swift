// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions

protocol EditableView {
    var isEditing: Bool { get }
    func setEditing(_ editing: Bool)
    func willToggleEditing()
    func didToggleEditing()
}

extension EditableView {
    func willToggleEditing() { }
    func didToggleEditing() { }

    func changeEditing(to value: Bool) {
        if value != isEditing {
            willToggleEditing()
            setEditing(value)
            didToggleEditing()
        }
    }
}

class EditingAction: Action {
    static let editableKey = "editable"

    class func standardActions() -> [Action] {
        return [
            StartEditingAction(identifier: "StartEditing"),
            StopEditingAction(identifier: "StopEditing"),
            ToggleEditingAction(identifier: "ToggleEditing")
        ]
    }
    
}

class StartEditingAction: EditingAction {
    override func validate(context: ActionContext) -> Validation {
        if let view = context[EditingAction.editableKey] as? EditableView {
            return Action.Validation(enabled: !view.isEditing)
        }
        
        return Validation(visible: false)
    }
    
    override func perform(context: ActionContext) {
        if let view = context[EditingAction.editableKey] as? EditableView {
            view.changeEditing(to: true)
        }
    }

}

class StopEditingAction: EditingAction {
    override func validate(context: ActionContext) -> Validation {
        if let view = context[EditingAction.editableKey] as? EditableView {
            return Action.Validation(enabled: !view.isEditing)
        }
        
        return Validation(visible: false)
    }
    
    override func perform(context: ActionContext) {
        if let view = context[EditingAction.editableKey] as? EditableView {
            view.changeEditing(to: false)
        }
    }
}

class ToggleEditingAction: EditingAction {
    
    override func validate(context: ActionContext) -> Validation {
        if let view = context[ToggleEditingAction.editableKey] as? EditableView {
            let name = view.isEditing ? "Done" : "Edit"
            return Action.Validation(enabled: true, visible: true, name: name)
        }
        
        return Validation(visible: false)
    }
    
    override func perform(context: ActionContext) {
        if let view = context[ToggleEditingAction.editableKey] as? EditableView {
            view.changeEditing(to: !view.isEditing)
        }
    }
}
