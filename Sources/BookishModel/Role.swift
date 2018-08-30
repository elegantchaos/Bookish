// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

public class Role: NSManagedObject {
    public static func role(named: String, context: NSManagedObjectContext) -> Role {
        let request: NSFetchRequest<Role> = Role.fetchRequest()
        request.predicate = NSPredicate(format: "name = \"\(named)\"")

        var role: Role
        if let results = try? context.fetch(request), results.count > 0 {
            role = results[0]
        } else {
            let newRole = Role(context: context)
            newRole.name = named
            role = newRole
        }
        
        return role
    }
}
