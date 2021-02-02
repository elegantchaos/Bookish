// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI
import SwiftUIExtensions

class CDBook: ExtensibleManagedObject {
}

extension CDBook {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBook> {
        return NSFetchRequest<CDBook>(entityName: "CDBook")
    }

    @NSManaged public var lists: NSSet?
}


// MARK: Generated accessors for lists
extension CDBook {

    @objc(addListsObject:)
    @NSManaged public func addToLists(_ value: CDList)

    @objc(removeListsObject:)
    @NSManaged public func removeFromLists(_ value: CDList)

    @objc(addLists:)
    @NSManaged public func addToLists(_ values: NSSet)

    @objc(removeLists:)
    @NSManaged public func removeFromLists(_ values: NSSet)

}

extension CDBook: AutoLinked {
    var linkView: some View {
        BookView(book: self)
    }
    var labelView: some View {
        Label(name, systemImage: "book")
    }
}
