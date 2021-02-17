// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData


/**
 Generic which gets an existing entity of a given identifier and type.
 */

internal func getWithId<EntityType: NSManagedObject>(_ identifier: EntityType.ID, type: EntityType.Type, in context: NSManagedObjectContext, createIfMissing: Bool) -> EntityType? where EntityType: Identifiable {
    let request: NSFetchRequest<EntityType> = EntityType.fetcher(in: context)
    request.predicate = NSPredicate(format: "id = %@", String(describing: identifier))
    if let results = try? context.fetch(request), let object = results.first {
        return object
    }

    if createIfMissing {
        let description = EntityType.self.entityDescription(in: context)
        if let object = NSManagedObject(entity: description, insertInto: context) as? EntityType {
            object.setValue(identifier, forKey: "id")
            return object
        }
    }

    return nil
}

/// A subclass of ExtensibleManagedObject which has a name and optional image associated with it.

class NamedManagedObject: ExtensibleManagedObject {
    @NSManaged public var name: String
    @NSManaged public var imageData: Data?
    @NSManaged public var imageURL: URL?

    /**
     Return the entity of our type with a given uuid.
     */
    
    public class func withId(_ id: ID, in context: NSManagedObjectContext) -> Self {
        return getWithId(id, type: self, in: context, createIfMissing: true)!
    }

    /**
     Return the entity of our type with a given uuid.
     */
    
    public class func withId(_ id: ID, in context: NSManagedObjectContext, createIfMissing: Bool = false) -> Self? {
        return getWithId(id, type: self, in: context, createIfMissing: createIfMissing)
    }
}

extension Array where Element == NamedManagedObject {
    var sortedByName: [Element] {
        return sorted { ($0.name == $1.name) ? ($0.id < $1.id) : ($0.name < $1.name) }
    }
}

// TODO: could we use a protocol to implement withId, instead of needing a subclass?
