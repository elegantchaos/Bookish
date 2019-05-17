// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel

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
        if let view = context[ToggleEditingAction.editableKey] as? EditableView, let selection = context[ActionContext.selectionKey] as? [ModelObject], selection.count > 0 {
            let kind = type(of: selection.first!).entityName
            let singular = (selection.count > 1) ? "\(kind).title" : "\(kind).title.singular"
            let name = view.isEditing ? "editing.stop.long" : "editing.start.long"
            let shortName = view.isEditing ? "editing.stop.short" : "editing.start.short"
            return Action.Validation(enabled: true, visible: true, name: name.localized(with: ["entity": singular.localized]), shortName: shortName.localized)
        }
        
        return Validation(visible: false)
    }
    
    override func perform(context: ActionContext) {
        if let view = context[ToggleEditingAction.editableKey] as? EditableView {
            view.changeEditing(to: !view.isEditing)
        }
    }
}
