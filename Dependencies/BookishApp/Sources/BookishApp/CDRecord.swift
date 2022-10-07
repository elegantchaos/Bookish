// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCore
import Combine
import CoreData
import Images
import JSONRepresentable
import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

class CDRecord: NSManagedObject, Identifiable {
    
    var fields: FieldList { cachedFields }

    private lazy var cachedFields: FieldList = decodedFields
    private lazy var cachedProperties: [String:CDProperty] = [:]

    var kind: RecordKind {
        get { RecordKind(rawValue: kindCode) ?? .unknown }
        set { kindCode = newValue.rawValue }
    }

    var isBook: Bool {
        kindCode == RecordKind.book.rawValue
    }
    
    var canDelete: Bool {
        switch kind {
            case .list, .group, .person, .book, .organisation, .series: return true
            default: return false
        }
    }
    
    var canExport: Bool {
        switch kind {
            case .list, .book: return true
            default: return false
        }
    }

    var canAddItems: Bool {
        switch kind {
            case .list: return true
            default: return false
        }
    }

    var canAddLinks: Bool {
        switch kind {
            case .book: return true
            default: return false
        }
    }
    
    var canAddLists: Bool {
        switch kind {
            case .group: return true
            case .root: return id == .rootListsID
            default: return false
        }
    }

    var canAddGroups: Bool {
        switch kind {
            case .group: return true
            case .root: return id == .rootListsID
            default: return false
        }
    }

    var watcher: AnyCancellable? = nil
    
    func sorted(ofKind kind: RecordKind) -> [CDRecord] {
        guard let lists = contents?.filter({ $0.kindCode == kind.rawValue }) else { return [] }
        let sorted = lists.sorted {
            return ($0.name == $1.name) ? ($0.id < $1.id) : ($0.name < $1.name)
        }

        return sorted

    }
    
    var sortedContents: [CDRecord] {
        contents?.sortedByName ?? []
    }

//    var sortedBooks: [CDRecord] {
//        return sorted(ofKind: .book)
//    }

    var sortedContainedBy: [CDRecord] {
        containedBy?.sortedByName ?? []
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
    
    func add(_ book: CDRecord) {
        addToContents(book)
    }
    
    func asBookRecord(from source: String) -> BookRecord? {
        var values: [String: Any] = [
            BookKey.title.rawValue: name
        ]
        
        if let p = properties {
            for property in p {
                values[property.key] = property.value
            }

        }

        return BookRecord(values, id: id, source: source)
    }
    

}

// MARK: Private Property Utilities.
// See CDRecord+Properties for the public property interface.

extension CDRecord {
    
    func propertyRecord(forKey key: String) -> CDProperty? {
        if let cached = cachedProperties[key] {
            return cached
        }
        
        guard let properties = properties else { return nil }
        
        for p in properties {
            cachedProperties[p.key] = p
            if p.key == key {
                return p
            }
        }
        
        return nil
    }
    
    func scheduleEncoding() {
        objectWillChange.send()
        encode(properties: cachedProperties)
    }
    
    private func encode(properties: [String:Any]) {
        do {
            let encoded = try PropertyListSerialization.data(fromPropertyList: properties, format: .xml, options: PropertyListSerialization.WriteOptions())
            self.codedProperties = String(data: encoded, encoding: .utf8)
        } catch {
            print("Failed to encoded properties: \(properties) \(error)")
        }
    }

}
