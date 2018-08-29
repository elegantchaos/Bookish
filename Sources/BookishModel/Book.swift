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
            let role = Role.role(named: "author", context: context)
            let authorEntry = PersonEntry(context: context)
            authorEntry.person = Person(context: context)
            authorEntry.role = role
            self.addToPeople(authorEntry)
        }
    }
    
}
