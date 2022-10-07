// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCore
import SwiftUI

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
    
    fileprivate var decodedProperties: [String:Any] {
        guard let data = codedProperties?.data(using: .utf8) else { return [:] }
        do {
            let decoded = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String:Any]
            return decoded ?? [:]
        } catch {
            return [:]
        }

    }
    
    

    /// Move all properties from this record to another
    func moveProperties(to target: CDRecord) {
        if let properties {
            for property in properties {
                target.addToProperties(property)
            }
        }
    }
}
