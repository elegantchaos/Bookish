// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData


extension NSManagedObject {

    /**
     Make a new instance in the given context.
     
     The default implementation of this uses +entity to look up the description,
     which causes warnings if more than once copy of the model has been loaded.
     
     We override it here and instead use the context we were given to look it up in the
     actual model that the context is using.
     */
    
    public convenience init(in context: NSManagedObjectContext) {
        let description = type(of: self).entityDescription(in: context)
        self.init(entity: description, insertInto: context)
    }
    
    /**
     Return an NSFetchRequest for a given model object class.
     
     Xcode generates a `fetchRequest` method which does pretty much the same thing,
     but it uses +entity to find the entity description.
     
     This version takes in the context and uses that to look up the description in the model.
     */
    
    public class func fetcher<T>(in context: NSManagedObjectContext) -> NSFetchRequest<T> where T: NSManagedObject {
        let request = NSFetchRequest<T>()
        request.entity = T.entityDescription(in: context)
        return request
    }
    
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
        return context.everyEntity(type: self, sorting: sorting)
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
