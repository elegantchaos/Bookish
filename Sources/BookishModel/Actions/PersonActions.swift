// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Actions

/**
 Protocol providing user interface actions.
 These aren't implemented in the model, but the protocol is defined
 here so that we can implement actions using it.
 */

public protocol PersonViewer {
    func reveal(person: Person)
}

/**
 Objects that want to observe changes to people
 should implement this protocol.
 */

public protocol PersonChangeObserver: ActionObserver {
    func added(role: PersonRole)
    func removed(role: PersonRole)
}

/**
 Objects that want to observe construction/destruction
 of people should implement this protocol.
 */

public protocol PersonConstructionObserver: ActionObserver {
    func created(person: Person)
    func deleted(person: Person)
}

/**
 Common functionality for all person-related actions.
 */

open class PersonAction: Action {
    public static let roleKey = "personRole"
    public static let personKey = "person"
    public static let newPersonKey = "newPerson"
    
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
            RevealPersonAction(identifier: "RevealPerson"),
            ChangeRolePersonAction(identifier: "ChangeRolePerson")
        ]
    }
}

/**
 Action that adds a person to a book.
 */

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
                
                context.forObservers { (observer: PersonChangeObserver) in
                    observer.added(role: role)
                }
            }
        }
    }
}

/**
 Action that removes a person from a book.
 */

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
            
            context.forObservers { (observer: PersonChangeObserver) in
                observer.removed(role: role)
            }
            
            if (role.books?.count ?? 0) == 0 {
                role.managedObjectContext?.delete(role)
            }
        }
        
    }
}

/**
 Action that creates a new person.
 */

class NewPersonAction: Action {
    public override func perform(context: ActionContext) {
        if let moc = context.info[ActionContext.modelKey] as? NSManagedObjectContext {
            let person = Person(context: moc)

            context.forObservers { (observer: PersonConstructionObserver) in
                observer.created(person: person)
            }
        }
    }
}

/**
 Action that deletes a person.
 */

class DeletePersonAction: Action {
    public override func perform(context: ActionContext) {
        if let selection = context.info[ActionContext.selectionKey] as? [Person],
            let moc = context.info[ActionContext.modelKey] as? NSManagedObjectContext {
            for person in selection {
                context.forObservers { (observer: PersonConstructionObserver) in
                    observer.deleted(person: person)
                }
                
                moc.delete(person)
            }
            
        }
    }
}

/**
 Action that reveals a person in the UI.
 */

class RevealPersonAction: PersonAction {
    override func validate(context: ActionContext) -> Bool {
        return (context.info[PersonAction.roleKey] as? PersonRole != nil) && super.validate(context: context)
    }
    
    override func perform(context: ActionContext) {
        if let role = context.info[PersonAction.roleKey] as? PersonRole, let person = role.person,
            let viewer = context.info[ActionContext.rootKey] as? PersonViewer {
            viewer.reveal(person: person)
        }
    }
}

/**
 Action that updates an existing role by changing the person that
 it applies to.
 */

class ChangeRolePersonAction: PersonAction {
    override func validate(context: ActionContext) -> Bool {
        return (context.info[PersonAction.roleKey] as? PersonRole != nil) && super.validate(context: context)
    }
    
    override func perform(context: ActionContext) {
        
        if
            let selection = context.info[ActionContext.selectionKey] as? [Book],
            let role = context.info[PersonAction.roleKey] as? PersonRole,
            let managedObjectContext = role.managedObjectContext,
            let roleName = role.role?.name {
            
            var newPerson = context.info[PersonAction.personKey] as? Person
            if newPerson == nil, let newPersonName = context.info[PersonAction.newPersonKey] as? String {
                print("Made new person \(newPersonName)")
                newPerson = Person(context: managedObjectContext)
                newPerson?.name = newPersonName
            }
            
            if let newPerson = newPerson {
                let newRole = newPerson.role(as: roleName)
                for book in selection {
                    book.removeFromPersonRoles(role)
                    book.addToPersonRoles(newRole)
                }
                
                print("\(roleName) changed from \(role.person!.name!) to \(newPerson.name!)")
            }
        }
    }
}


