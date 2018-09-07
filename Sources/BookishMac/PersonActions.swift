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
    static let ObserverKey = "personObserver"
    static let RoleKey = "personRole"
    static let MenuKey = "personMenu"
}

class InsertPersonAction: PersonAction {
    override func perform(context: ActionContext) {
        if context.parameters.count > 0 {
            let roleName = context.parameters[0]
            if
                let selection = context.info[ActionContext.SelectionKey] as? [Book],
                let viewModel = context.info[ActionContext.ModelKey] as? CollectionDocumentViewModel {
                let person = Person(context: viewModel.managedObjectContext)
                let role = person.role(as: roleName)
                for book in selection {
                    book.addToPersonRoles(role)
                }
                
                context.forEach(key: PersonAction.ObserverKey) { (observer: PersonChangeObserver) in
                    observer.added(role: role)
                }
            }
        }
    }
}

class RemovePersonAction: PersonAction {
    override func perform(context: ActionContext) {
        if
            let selection = context.info[ActionContext.SelectionKey] as? [Book],
            let role = context.info[PersonAction.RoleKey] as? PersonRole {
            for book in selection {
                book.removeFromPersonRoles(role)
            }
            
            context.forEach(key: PersonAction.ObserverKey) { (observer: PersonChangeObserver) in
                observer.removed(role: role)
            }
        }
        
    }
}

class ShowAddPersonAction: PersonAction {
    override func perform(context: ActionContext) {
        if
            let event = NSApplication.shared.currentEvent,
            let viewModel = context.info[ActionContext.ModelKey] as? CollectionDocumentViewModel,
            let view = context.sender as? NSView {
            NSMenu.popUpContextMenu(viewModel.addPersonMenu, with: event, for: view)
        }
    }
}

