// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import CoreData
import Actions
import AppKit

protocol PersonChangeObserver {
    func added(role: PersonRole)
    func removed(role: PersonRole)
}

class PersonAction: Action {
    static let observerKey = "personObserver"
    static let roleKey = "personRole"

    override func validate(context: ActionContext) -> Bool {
        guard let selection = context.info[ActionContext.selectionKey] as? [Book] else {
            return false
        }
        
        guard let _ = context.info[ActionContext.modelKey] as? CollectionDocumentViewModel else {
            return false
        }
        
        return selection.count > 0
    }
}

class InsertPersonAction: PersonAction {
    override func validate(context: ActionContext) -> Bool {
        return (context.parameters.count > 0) && super.validate(context: context)
    }
    
    override func perform(context: ActionContext) {
        if context.parameters.count > 0 {
            let roleName = context.parameters[0]
            if
                let selection = context.info[ActionContext.selectionKey] as? [Book],
                let viewModel = context.info[ActionContext.modelKey] as? CollectionDocumentViewModel {
                let person = Person(context: viewModel.managedObjectContext)
                let role = person.role(as: roleName)
                for book in selection {
                    book.addToPersonRoles(role)
                }
                
                context.forEach(key: PersonAction.observerKey) { (observer: PersonChangeObserver) in
                    observer.added(role: role)
                }
            }
        }
    }
}

class RemovePersonAction: PersonAction {
    override func validate(context: ActionContext) -> Bool {
        return (context.info[PersonAction.roleKey] as? PersonRole != nil) && super.validate(context: context)
    }
    
    override func perform(context: ActionContext) {
        if
            let selection = context.info[ActionContext.selectionKey] as? [Book],
            let role = context.info[PersonAction.roleKey] as? PersonRole {
            for book in selection {
                book.removeFromPersonRoles(role)
            }
            
            context.forEach(key: PersonAction.observerKey) { (observer: PersonChangeObserver) in
                observer.removed(role: role)
            }
            
            if (role.books?.count ?? 0) == 0 {
                role.managedObjectContext?.delete(role)
            }
        }
        
    }
}

class ShowAddPersonAction: PersonAction {
    override func perform(context: ActionContext) {
        if let event = NSApplication.shared.currentEvent, let viewModel = context.info[ActionContext.modelKey] as? CollectionDocumentViewModel {
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

