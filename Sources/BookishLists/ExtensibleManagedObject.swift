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
    @NSManaged public var properties: Set<CDProperty>?

    class DecodedProperty {
        let property: CDProperty
        var value: Any
        
        init(for object: ExtensibleManagedObject) {
            self.value = ""
            self.property = CDProperty(context: object.managedObjectContext!)
            object.addToProperties(property)
        }
        
        init?(property: CDProperty) {
            do {
                self.value = try PropertyListSerialization.propertyList(from: property.value, options: [], format: nil)
                self.property = property
            } catch {
                print("Failed to decode property")
                return nil
            }
        }
    }

    fileprivate lazy var cachedProperties: [String:DecodedProperty] = [:]

    override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }

    func binding(forProperty key: String) -> Binding<String> {
        Binding<String> { () -> String in
            return self.string(forKey: key) ?? ""
        } set: { (value) in
            self.set(value, forKey: key)
        }
    }
    
    var sortedKeys: [String] {
        guard let properties = properties else { return [] }
        return properties.map({ $0.key })
    }

    func property(forKey key: String) -> Any? {
        if let cached = cachedProperties[key] {
            return cached.value
        }
        
        guard let properties = properties else { return nil }
        
        for p in properties {
            if p.key == key, let decoded = DecodedProperty(property: p) {
                cachedProperties[key] = decoded
                return decoded.value
            }
        }
        
        return nil
    }

    func makeProperty(forKey key: String) -> DecodedProperty {
        let decoded = DecodedProperty(for: self)
        cachedProperties[key] = decoded
        return decoded
    }
    
    func setProperty(_ value: Any, forKey key: String) {
        
        let cached = cachedProperties[key] ?? makeProperty(forKey: key)
        cached.value = value
        DispatchQueue.global(qos: .background).async {
            do {
                let encoded = try PropertyListSerialization.data(fromPropertyList: value, format: .xml, options: PropertyListSerialization.WriteOptions())
                self.managedObjectContext?.perform {
                    cached.property.value = encoded
                }
            } catch {
                print("Failed to encoded property \(key) with value \(value)")
            }
        }
    }
    
    func string(forKey key: String) -> String? {
        return property(forKey: key) as? String
    }

    func dict<K,V>(forKey key: String) -> [K:V]? {
        return property(forKey: key) as? [K:V]
    }
    
    func array<V>(forKey key: String) -> [V]? {
        return property(forKey: key) as? [V]
    }
    
    func set(_ value: String, forKey key: String) {
        setProperty(value, forKey: key)
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

// MARK: Generated accessors for properties
extension ExtensibleManagedObject {

    @objc(addPropertiesObject:)
    @NSManaged public func addToProperties(_ value: CDProperty)

    @objc(removePropertiesObject:)
    @NSManaged public func removeFromProperties(_ value: CDProperty)

    @objc(addProperties:)
    @NSManaged public func addToProperties(_ values: NSSet)

    @objc(removeProperties:)
    @NSManaged public func removeFromProperties(_ values: NSSet)

}
