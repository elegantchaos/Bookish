// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

public class Edition: NSManagedObject {
    static var untitledCount = 0
    
    override public init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto:context)
    }
    
    public override func awakeFromInsert() {
        name = "Untitled \(Edition.untitledCount)"
        Edition.untitledCount += 1
        
        if let context = managedObjectContext {
            volumes = Volume(context: context)
        }
    }
}
