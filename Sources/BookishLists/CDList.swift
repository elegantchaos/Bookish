// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Combine
import CoreData
import Images
import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

class CDList: NamedManagedObject {
    @NSManaged public var container: CDList?

    fileprivate lazy var cachedFields: FieldList = decodedFields
    
    var fields: FieldList { cachedFields }
    var watcher: AnyCancellable? = nil
    
    var sortedLists: [CDList] {
        guard let lists = lists else { return [] }
        let sorted = lists.sorted {
            return ($0.name == $1.name) ? ($0.id < $1.id) : ($0.name < $1.name)
        }

        return sorted
    }
    
    var sortedBooks: [CDBook] {
        guard let books = books else { return [] }
        let sorted = books.sorted {
            return ($0.name == $1.name) ? ($0.id < $1.id) : ($0.name < $1.name)
        }
        
        return sorted
    }

    fileprivate var decodedFields: FieldList {
        let list = FieldList(decodedFrom: array(forKey: "fields") ?? [])
        watcher = list.objectWillChange.sink {
            print("Fields changed")
            self.scheduleFieldEncoding()
        }
        return list
    }

    fileprivate func scheduleFieldEncoding() {
        onMainQueue { [self] in
            let strings = fields.encoded
            set(strings, forKey: "fields")
            print("Encoded as \(strings)")
        }
    }
    
    func add(_ book: CDBook) {
        addToBooks(book)
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
    @NSManaged fileprivate func addToBooks(_ value: CDBook)

    @objc(removeBooksObject:)
    @NSManaged fileprivate func removeFromBooks(_ value: CDBook)

    @objc(addBooks:)
    @NSManaged fileprivate func addToBooks(_ values: NSSet)

    @objc(removeBooks:)
    @NSManaged fileprivate func removeFromBooks(_ values: NSSet)

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

extension String {
    static let allPeopleID = "all-people"
    static let allPublishersID = "all-publishers"
    static let allImportsID = "all-imports"
}

extension CDList {
    static func allPeople(in context: NSManagedObjectContext) -> CDList {
        if let list = CDList.withId(.allPeopleID, in: context, createIfMissing: false) {
            return list
        }

        let list = CDList.withId(.allPeopleID, in: context)
        list.name = "People"
        return list
    }

    static func allPublishers(in context: NSManagedObjectContext) -> CDList {
        if let list = CDList.withId(.allPublishersID, in: context, createIfMissing: false) {
            return list
        }

        let list = CDList.withId(.allPublishersID, in: context)
        list.name = "Publishers"
        return list
    }

    static func allImports(in context: NSManagedObjectContext) -> CDList {
        if let list = CDList.withId(.allImportsID, in: context, createIfMissing: false) {
            return list
        }

        let list = CDList.withId(.allImportsID, in: context)
        list.name = "Imports"
        return list
    }

}
