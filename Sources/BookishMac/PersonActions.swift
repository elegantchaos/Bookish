// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import CoreData

protocol PersonChangeObserver {
    func added(role: PersonRole)
    func removing(role: PersonRole)
}

class PersonAction: Action {
    static let ObserverKey = "personObserver"
    static let RoleKey = "personRole"
}

class InsertPersonAction: PersonAction {
    override func perform(context: ActionContext) {
        if context.parameters.count > 0 {
            let roleName = context.parameters[0]
            if
                let selection = context.info[ActionContext.SelectionKey] as? [Book],
                let moc = context.info[ActionContext.ModelObjectContextKey] as? NSManagedObjectContext {
                let person = Person(context: moc)
                let role = person.role(as: roleName)
                for book in selection {
                    book.addToPersonRoles(role)
                }

                if let observer = context.info[PersonAction.ObserverKey] as? PersonChangeObserver {
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

            if let observer = context.info[PersonAction.ObserverKey] as? PersonChangeObserver {
                observer.removing(role: role)
            }
        }

    }
}
