// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Combine
import CoreData
import Images
import SwiftUI
import SwiftUIExtensions

class CDList: NamedManagedObject {
    @NSManaged public var container: CDList?

    fileprivate lazy var cachedFields: [ListField] = decodedFields
    fileprivate var watchers: [AnyCancellable] = []
    
    var fields: [ListField] { cachedFields }
    
    var sortedLists: [CDList] {
        guard let lists = lists else { return [] }
        let sorted = lists.sorted {
            return ($0.name == $1.name) ? ($0.id < $1.id) : ($0.name < $1.name)
        }

        return sorted
    }
    
    var sortedEntries: [CDEntry] {
        guard let entries = entries else { return [] }
        let sorted = entries.sorted {
            return ($0.book.name == $1.book.name) ? ($0.book.id < $1.book.id) : ($0.book.name < $1.book.name)
        }
        
        return sorted
    }

    var decodedFields: [ListField] {
        let strings: [String] = array(forKey: "fields") ?? []
        print(strings)
        return strings.map({ string in
            let items = string.split(separator: "•", maxSplits: 1)
            let kind = ListField.Kind(rawValue: String(items[0])) ?? .string
            let field = ListField(key: String(items[1]), kind: kind)
            
            let watcher = field.objectWillChange.sink {
                self.scheduleFieldEncoding()
            }
            
            self.watchers.append(watcher)
            
            return field
        })
    }

    func newField() {
        addField()
    }
    
    func addField(name: String? = nil, kind: ListField.Kind = .string) {
        objectWillChange.send()
        let key = name ?? "Untitled \(kind)"
        cachedFields.append(ListField(key: key, kind: kind))
        scheduleFieldEncoding()
    }
    
    func moveFields(fromOffsets from: IndexSet, toOffset to: Int) {
        cachedFields.move(fromOffsets: from, toOffset: to)
        scheduleFieldEncoding()
    }

    func deleteFields(atOffsets offsets: IndexSet) {
        cachedFields.remove(atOffsets: offsets)
        scheduleFieldEncoding()
    }
    
    func scheduleFieldEncoding() {
        let strings = cachedFields.map({ field in
            "\(field.kind)•\(field.key)"
        })
        set(strings, forKey: "fields")
        print(strings)
    }
    
    func add(_ book: CDBook) {
        if let context = self.managedObjectContext {
            let entry = CDEntry(context: context)
            entry.book = book
            entry.list = self
        }
    }
}

extension CDList {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDList> {
        return NSFetchRequest<CDList>(entityName: "CDList")
    }
    
    @NSManaged public var entries: Set<CDEntry>?
    @NSManaged public var lists: Set<CDList>?
}

extension CDList {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: CDEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: CDEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSSet)

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
