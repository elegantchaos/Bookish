// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

public class Person: NSManagedObject {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        name = "Untitled Person"
    }
    
    /**
            If there's already an entry for a given role for this person, return it.
            If not, create it.
     */
    
    public func role(as roleName: String) -> PersonRole {
        guard let context = self.managedObjectContext else {
            fatalError("context not set")
        }
        
        let role = Role.role(named: roleName, context: context)
        
        let request: NSFetchRequest<PersonRole> = PersonRole.fetchRequest()
        request.predicate = NSPredicate(format: "(person = %@) and (role = %@)", self, role)
        
        var entry: PersonRole
        if let results = try? context.fetch(request), results.count > 0 {
            entry = results[0]
        } else {
            entry = PersonRole(context: context)
            entry.person = self
            entry.role = role
        }
        
        return entry
    }
}
