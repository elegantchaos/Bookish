// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Actions
import AppKit

public protocol PersonChangeObserver {
    func added(role: PersonRole)
    func removed(role: PersonRole)
}

public protocol PersonConstructionObserver {
    func created(person: Person)
    func deleted(person: Person)
}

open class PersonAction: Action {
    public static let observerKey = "personObserver"
    public static let roleKey = "personRole"

    open override func validate(context: ActionContext) -> Bool {
        guard let selection = context.info[ActionContext.selectionKey] as? [Book] else {
            return false
        }
        
        guard let _ = context.info[ActionContext.modelKey] as? NSManagedObjectContext else {
            return false
        }
        
        return selection.count > 0
    }
    
    open class func standardActions() -> [Action] {
        return [
            NewPersonAction(identifier: "NewPerson"),
            AddPersonAction(identifier: "AddPerson"),
            RemovePersonAction(identifier: "RemovePerson"),
            DeletePersonAction(identifier: "DeletePerson"),
        ]
    }
}

class AddPersonAction: PersonAction {
    public override func validate(context: ActionContext) -> Bool {
        return (context.parameters.count > 0) && super.validate(context: context)
    }
    
    public override func perform(context: ActionContext) {
        if context.parameters.count > 0 {
            let roleName = context.parameters[0]
            if
                let selection = context.info[ActionContext.selectionKey] as? [Book],
                let moc = context.info[ActionContext.modelKey] as? NSManagedObjectContext {
                let person = Person(context: moc)
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
    public override func validate(context: ActionContext) -> Bool {
        return (context.info[PersonAction.roleKey] as? PersonRole != nil) && super.validate(context: context)
    }
    
    public override func perform(context: ActionContext) {
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

class NewPersonAction: Action {
    public override func perform(context: ActionContext) {
        if let moc = context.info[ActionContext.modelKey] as? NSManagedObjectContext {
            let person = Person(context: moc)

            context.forEach(key: PersonAction.observerKey) { (observer: PersonConstructionObserver) in
                observer.created(person: person)
            }
        }
    }
}

class DeletePersonAction: Action {
    public override func perform(context: ActionContext) {
        if let selection = context.info[ActionContext.selectionKey] as? [Person],
            let moc = context.info[ActionContext.modelKey] as? NSManagedObjectContext {
            for person in selection {
                context.forEach(key: PersonAction.observerKey) { (observer: PersonConstructionObserver) in
                    observer.deleted(person: person)
                }
                
                moc.delete(person)
            }
            
        }
    }
}



