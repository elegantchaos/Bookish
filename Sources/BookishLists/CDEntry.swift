// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/02/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

class CDEntry: ExtensibleManagedObject {
}

extension CDEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDEntry> {
        return NSFetchRequest<CDEntry>(entityName: "CDEntry")
    }
}
