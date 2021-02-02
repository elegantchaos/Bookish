// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI
import SwiftUIExtensions

class CDList: ExtensibleManagedObject {
    @NSManaged public var container: CDList?

    var sortedBooks: [CDBook] {
        guard let books = books else { return [] }
        let sorted = books.sorted { $0.name < $1.name }
        return sorted
    }
    
    var children: [NSManagedObject]? {
        guard let books = books else { return nil }
        return Array(books)
    }
}

extension CDList {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDList> {
        return NSFetchRequest<CDList>(entityName: "CDList")
    }
    
    @NSManaged public var books: Set<CDBook>?
    @NSManaged public var lists: Set<CDList>?
}

extension CDList {

    @objc(addBooksObject:)
    @NSManaged public func addToBooks(_ value: CDBook)

    @objc(removeBooksObject:)
    @NSManaged public func removeFromBooks(_ value: CDBook)

    @objc(addBooks:)
    @NSManaged public func addToBooks(_ values: NSSet)

    @objc(removeBooks:)
    @NSManaged public func removeFromBooks(_ values: NSSet)

}

extension CDList {

    @objc(addListsObject:)
    @NSManaged public func addToLists(_ value: CDList)

    @objc(removeListsObject:)
    @NSManaged public func removeFromLists(_ value: CDList)

    @objc(addLists:)
    @NSManaged public func addToLists(_ values: NSSet)

    @objc(removeLists:)
    @NSManaged public func removeFromLists(_ values: NSSet)

}

extension CDList: AutoLinked {
    var linkView: some View {
        ListView(list: self)
    }
    var labelView: some View {
        Label(name, systemImage: "books.vertical")
    }
}
