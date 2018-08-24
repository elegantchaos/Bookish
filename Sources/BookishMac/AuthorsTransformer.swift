// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa
import BookishModel

class AuthorsTransformer: ValueTransformer, CoreDataTransformer {
    static let name = NSValueTransformerName(rawValue: "AuthorsToString")

    var managedObjectContext: NSManagedObjectContext?
    
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let authors = value as? Set<Author> else {
            return ""
        }
        
        let names: [String] = authors.map { $0.name ?? "" }
        return names.joined(separator: ",")
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        var result: [Author] = []
        if let text = value as? String, let context = managedObjectContext {
            let names = text.split(separator: ",")
            print(names)
            for name in names {
                let author = Author(context: context)
                author.name = String(name)
                result.append(author)
            }
        }
        
        return NSSet(array: result)
    }
    
}
