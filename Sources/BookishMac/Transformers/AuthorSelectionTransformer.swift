// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BookishModel

class AuthorSelectionTransformer: ValueTransformer {
    static let name = NSValueTransformerName(rawValue: "PersonSelection")

    var originalRole: Relationship?

    override func transformedValue(_ value: Any?) -> Any? {
        guard let role = value as? Relationship else {
            return ""
        }
        
        self.originalRole = role
        return role.person?.name ?? ""
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let text = value as? String, let originalRole = originalRole, let context = originalRole.managedObjectContext {
            let request: NSFetchRequest<Person> = Person.fetchRequest()
            request.predicate = NSPredicate(format: "name = \"\(text)\"")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            if let results = try? context.fetch(request) {
                if let person = results.first {
                    return person
                }
            }
            
        }
        return nil
    }

}
