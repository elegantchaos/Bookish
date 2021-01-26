// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI
import SwiftUIExtensions

class CDBook: NSManagedObject {
    func binding(forProperty key: String) -> Binding<String> {
        Binding<String> { () -> String in
            return self.decodedProperties[key] ?? ""
        } set: { (value) in
            var updated = self.decodedProperties
            updated[key] = value
            self.encode(properties: updated)
        }
    }
    
    var decodedProperties: [String:String] {
        guard let data = properties?.data(using: .utf8) else { return [:] }
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode([String:String].self, from: data)
            return decoded
        } catch {
            return [:]
        }

    }
    
    func encode(properties: [String:String]) {
        let encoder = JSONEncoder()
        do {
            let json = try encoder.encode(properties)
            self.properties = String(data: json, encoding: .utf8)
        } catch {
            print("Failed to encoded properties: \(properties) \(error)")
        }
    }
}

extension CDBook: AutoLinked {
    var linkView: some View {
        BookView(book: self)
    }
    var labelView: some View {
        Label(name ?? "Untitled", systemImage: "book")
    }
}
