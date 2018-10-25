// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import AppKit

class PersonUIAction: PersonAction {
    override class func standardActions() -> [Action] {
        return [
            FillPersonMenuAction(identifier: "FillPersonMenu"),
            PopupPersonMenuAction(identifier: "PopupPersonMenu"),
        ]
    }
}

class FillPersonMenuAction: PersonUIAction {
    override func validate(context: ActionContext) -> Bool {
        guard super.validate(context: context) else {
            return false
        }
        
        if let item = context.sender as? NSMenuItem, let viewModel = context.info[ActionContext.viewModelKey] as? CollectionDocumentViewModel {
            item.submenu = viewModel.addPersonMenu
            return true
        }
        
        return false
    }
}



class PopupPersonMenuAction: PersonUIAction {
    override func perform(context: ActionContext) {
        if let event = NSApplication.shared.currentEvent, let viewModel = context.info[ActionContext.viewModelKey] as? CollectionDocumentViewModel {
            var view = context.sender as? NSView
            if view == nil {
                view = (context.sender as? NSToolbarItem)?.view
            }
            
            if let view = view {
                NSMenu.popUpContextMenu(viewModel.addPersonMenu, with: event, for: view)
            }
        }
    }
}

