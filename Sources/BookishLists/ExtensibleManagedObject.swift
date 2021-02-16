// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI

/// An NSManagedObject subclass which supports additional dynamic properties.
/// The extra properties are encoded as data and stored in a single core-data
/// attribute called `codedProperties`.

class ExtensibleManagedObject: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged fileprivate var codedProperties: String?

    fileprivate lazy var cachedProperties: [String:Any] = decodedProperties

    override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }

    func binding(forProperty key: String) -> Binding<String> {
        Binding<String> { () -> String in
            return (self.decodedProperties[key] as? String) ?? ""
        } set: { (value) in
            var updated = self.decodedProperties
            updated[key] = value
            self.encode(properties: updated)
        }
    }
    
    var sortedKeys: [String] {
        cachedProperties.keys.sorted()
    }

    func property(forKey key: String) -> Any? {
        return cachedProperties[key]
    }

    func string(forKey key: String) -> String? {
        return cachedProperties[key] as? String
    }

    func dict<K,V>(forKey key: String) -> [K:V]? {
        return cachedProperties[key] as? [K:V]
    }
    
    func array<V>(forKey key: String) -> [V]? {
        return cachedProperties[key] as? [V]
    }
    
    func set(_ value: String, forKey key: String) {
        cachedProperties[key] = value
        scheduleEncoding()
    }
    
    func set<V>(_ value: [V], forKey key: String) {
        cachedProperties[key] = value
        scheduleEncoding()
    }
    
    func set<K,V>(_ value: [K:V], forKey key: String) {
        cachedProperties[key] = value
        scheduleEncoding()
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
            let json = try PropertyListSerialization.data(fromPropertyList: properties, format: .xml, options: PropertyListSerialization.WriteOptions())
            self.codedProperties = String(data: json, encoding: .utf8)
        } catch {
            print("Failed to encoded properties: \(properties) \(error)")
        }
    }

}
