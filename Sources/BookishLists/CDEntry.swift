// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/02/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI
import SwiftUIExtensions

class CDEntry: ExtensibleManagedObject {
    @NSManaged public var book: CDBook
    @NSManaged public var list: CDList
}

extension CDEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDEntry> {
        return NSFetchRequest<CDEntry>(entityName: "CDEntry")
    }
}

extension CDEntry: AutoLinked {
    var linkView: some View {
        assert(isDeleted == false)
        return EntryView(entry: self)
    }
    var labelView: some View {
        assert(isDeleted == false)
        return ImageOwnerLabelView(object: book)
    }
}
