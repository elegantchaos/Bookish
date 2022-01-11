// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData


extension NSManagedObject {
    
    /**
     Return count of instances of a given entity type.
     */
    
    public class func countEntities(in context: NSManagedObjectContext) -> Int {
        return context.countEntities(type: self)
    }
    
    /**
     Return every instance of a given entity type.
     */
    
    public class func everyEntity<T: NSManagedObject>(in context: NSManagedObjectContext, sorting: [NSSortDescriptor]? = nil) -> [T] {
        let entities: [T] = context.everyEntity(type: T.self, sorting: sorting)
        return entities
    }
    
    /**
     Return the entity description for this type in a given context.
     */
    
    public class func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        return context.entityDescription(for: self)
    }
    
    /**
     Return the entity description for this instance.
     */
    
    public func entityDescription() -> NSEntityDescription {
        return type(of: self).entityDescription(in: self.managedObjectContext!)
    }

}
