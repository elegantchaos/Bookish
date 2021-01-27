// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

class IdentifiableManagedObject: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID

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
