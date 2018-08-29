// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

public class Book: NSManagedObject {
    
    static var untitledCount = 0
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        name = "Untitled \(Book.untitledCount)"
        Book.untitledCount += 1
        
        if let context = managedObjectContext {
            
            let request: NSFetchRequest<Role> = Role.fetchRequest()
            request.predicate = NSPredicate(format: "name = \"author\"")
            
            var role: Role?
            if let results = try? context.fetch(request), results.count > 0 {
                role = results[0]
            } else {
                let newRole = Role(context: context)
                newRole.name = "author"
                role = newRole
            }
            
            let authorEntry = PersonEntry(context: context)
            authorEntry.addToBooks(self)
            authorEntry.person = Person(context: context)
            authorEntry.role = role
            self.addToPeople(authorEntry)
        }
    }
    
}
