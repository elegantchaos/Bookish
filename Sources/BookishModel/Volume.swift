// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

public class Volume: NSManagedObject {
    
    public override func awakeFromInsert() {
        name = "Untitled \(Edition.untitledCount)"
        Edition.untitledCount += 1
        
        if let context = managedObjectContext {
            author = Person(context: context)
        }
    }

}
