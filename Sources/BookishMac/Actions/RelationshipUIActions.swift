// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import AppKit

class RelationshipUIAction: ModelAction {
    override class func standardActions() -> [Action] {
        return [
            FillRelationshipMenuAction(identifier: "FillRelationshipMenu"),
            ShowAddRelationshipMenuAction(identifier: "ShowAddRelationshipMenu"),
        ]
    }
}

class FillRelationshipMenuAction: RelationshipUIAction {
    override func validate(context: ActionContext) -> Bool {
        guard super.validate(context: context) else {
            return false
        }
        
        if let item = context.sender as? NSMenuItem, let viewModel = context.info[ActionContext.viewModelKey] as? CollectionViewModel {
            item.submenu = viewModel.addRelationshipMenu
            return true
        }
        
        return false
    }
}



class ShowAddRelationshipMenuAction: RelationshipUIAction {
    open override func perform(context: ActionContext, completed: @escaping Completion) {
        if let event = NSApplication.shared.currentEvent, let viewModel = context.info[ActionContext.viewModelKey] as? CollectionViewModel {
            var view = context.sender as? NSView
            if view == nil {
                view = (context.sender as? NSToolbarItem)?.view
            }
            
            if let view = view {
                NSMenu.popUpContextMenu(viewModel.addRelationshipMenu, with: event, for: view)
            }
        }
        completed()
    }
}

