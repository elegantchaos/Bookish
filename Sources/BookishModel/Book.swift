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
        
        added = Date()
        modified = Date()
        
        if let context = managedObjectContext {
            let author = Person(context: context)
            let entry = author.role(as: "author")
            entry.addToBooks(self)
        }
    }
    
    public var roles: Set<Role> {
        var result = Set<Role>()
        if let people = self.personRoles as? Set<PersonRole> {
            for entry in people {
                if let role = entry.role {
                    result.insert(role)
                }
            }
        }
        
        return result
    }

    public var people: Set<Person> {
        var result = Set<Person>()
        if let people = self.personRoles as? Set<PersonRole> {
            for entry in people {
                if let person = entry.person {
                    result.insert(person)
                }
            }
        }
        
        return result
    }

}
