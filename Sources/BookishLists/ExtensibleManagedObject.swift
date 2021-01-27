// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI

class ExtensibleManagedObject: IdentifiableManagedObject {
    @NSManaged public var name: String
    @NSManaged public var properties: String?

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
    
    var decodedProperties: [String:Any] {
        guard let data = properties?.data(using: .utf8) else { return [:] }
        do {
            let decoded = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
            return decoded ?? [:]
        } catch {
            return [:]
        }

    }
    
    func encode(properties: [String:Any]) {
        do {
            let json = try JSONSerialization.data(withJSONObject: properties, options: [])
            self.properties = String(data: json, encoding: .utf8)
        } catch {
            print("Failed to encoded properties: \(properties) \(error)")
        }
    }

}
