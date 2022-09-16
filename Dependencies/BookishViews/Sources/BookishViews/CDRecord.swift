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
    enum Kind: Int16 {
        case unknown
        case root
        case group
        case list
        case book
        case role
        case roleList
        case person
        case publisher
        case series
        case entry
        case importSession
    }
    
    fileprivate lazy var cachedFields: FieldList = decodedFields
    
    var fields: FieldList { cachedFields }
    fileprivate lazy var cachedProperties: [String:CDProperty] = [:]

    var kind: Kind {
        get { Kind(rawValue: kindCode) ?? .unknown }
        set { kindCode = newValue.rawValue }
    }

    var isBook: Bool {
        kindCode == Kind.book.rawValue
    }
    
    var canDelete: Bool {
        switch kind {
            case .list, .group: return true
            default: return false
        }
    }
    
    var canExport: Bool {
        switch kind {
            case .list, .book: return true
            default: return false
        }
    }
    
    var canAddLinks: Bool {
        switch kind {
            case .book, .list: return true
            default: return false
        }
    }
    
    var canAddLists: Bool {
        switch kind {
            case .group: return true
            case .root: return id == ModelController.RootList.lists.id
            default: return false
        }
    }

    var canAddGroups: Bool {
        switch kind {
            case .group: return true
            case .root: return id == ModelController.RootList.lists.id
            default: return false
        }
    }

    var watcher: AnyCancellable? = nil
    
    func sorted(ofKind kind: Kind) -> [CDRecord] {
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


// MARK: Properties

extension CDRecord {
    func binding(forProperty key: String) -> Binding<String> {
        Binding<String> { () -> String in
            return self.string(forKey: key) ?? ""
        } set: { (value) in
            self.set(value, forKey: key)
        }
    }
    
    var sortedKeys: [String] {
        guard let properties = properties else { return [] }
        let keys = properties.map({ $0.key })
        let uniqued = Set(keys)
        if keys.count > uniqued.count {
            print("Duplicate keys present!")
        }
        let sorted = uniqued.sorted()
        return sorted
    }

    func makeRecord(forKey key: String) -> CDProperty {
        let record = CDProperty(context: managedObjectContext!)
        record.key = key
        addToProperties(record)
        return record
    }
    
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

    func property(forKey key: String) -> Any? {
        let record = propertyRecord(forKey: key)
        return record?.value
    }
    
    func removeProperty(forKey key: String) {
        if let record = propertyRecord(forKey: key) {
            managedObjectContext?.delete(record)
        }
    }
    
    func setProperty(_ value: Any, forKey key: String) {
        let record = propertyRecord(forKey: key) ?? makeRecord(forKey: key)
        record.value = value
    }
    
    func string(forKey key: String) -> String? {
        return property(forKey: key) as? String
    }

    func integer(forKey key: String) -> Int? {
        return property(forKey: key) as? Int
    }

    func double(forKey key: String) -> Double? {
        return property(forKey: key) as? Double
    }

    func strings(forKey key: String) -> [String] {
        guard let joined = string(forKey: key) else { return [] }
        return joined.split(separator: ",").map({ String($0) })
    }
    
    func date(forKey key: String) -> Date? {
        return property(forKey: key) as? Date
    }

    func dict<K,V>(forKey key: String) -> [K:V]? {
        return property(forKey: key) as? [K:V]
    }
    
    func array<V>(forKey key: String) -> [V]? {
        return property(forKey: key) as? [V]
    }
    
    func set(_ value: String?, forKey key: String) {
        if let value = value {
            setProperty(value, forKey: key)
        } else {
            removeProperty(forKey: key)
        }
    }
    
    func set(_ value: Date?, forKey key: String) {
        if let value = value {
            setProperty(value, forKey: key)
        } else {
            removeProperty(forKey: key)
        }
    }
    
    func set<V>(_ value: [V], forKey key: String) {
        setProperty(value, forKey: key)
    }
    
    func set<K,V>(_ value: [K:V], forKey key: String) {
        setProperty(value, forKey: key)
    }
 
    func merge(properties: [String:Any]) {
        for item in properties {
            setProperty(item.value, forKey: item.key)
        }
    }
    
    func set(_ value: String, forKey key: BookKey) {
        set(value, forKey: key.rawValue)
    }
    
    func set(_ value: Date, forKey key: BookKey) {
        set(value, forKey: key.rawValue)
    }
    
    fileprivate func scheduleEncoding() {
        objectWillChange.send()
        encode(properties: cachedProperties)
    }
    
    fileprivate var decodedProperties: [String:Any] {
        guard let data = codedProperties?.data(using: .utf8) else { return [:] }
        do {
            let decoded = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String:Any]
            return decoded ?? [:]
        } catch {
            return [:]
        }

    }
    
    fileprivate func encode(properties: [String:Any]) {
        do {
            let encoded = try PropertyListSerialization.data(fromPropertyList: properties, format: .xml, options: PropertyListSerialization.WriteOptions())
            self.codedProperties = String(data: encoded, encoding: .utf8)
        } catch {
            print("Failed to encoded properties: \(properties) \(error)")
        }
    }

}
