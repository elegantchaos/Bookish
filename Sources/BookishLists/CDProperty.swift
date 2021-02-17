// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/02/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI
import SwiftUIExtensions

class CDProperty: NSManagedObject {
    @NSManaged public var key: String
    @NSManaged public var value: Data
}

extension CDProperty {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDProperty> {
        return NSFetchRequest<CDProperty>(entityName: "CDProperty")
    }
}
