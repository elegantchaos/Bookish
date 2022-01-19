// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/02/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI
import SwiftUIExtensions

public class CDProperty: NSManagedObject {
    @NSManaged public var key: String
    @NSManaged fileprivate var encodedValue: Data
    
    private var decodedProperty: Any?
    
    var value: Any {
        get {
            if decodedProperty == nil {
                do {
                    decodedProperty = try PropertyListSerialization.propertyList(from: encodedValue, options: [], format: nil)
                } catch {
                    print("Failed to decode property")
                    decodedProperty = NSNull()
                }
            }

            return decodedProperty!
        }

        set(newValue) {
            decodedProperty = newValue
//            managedObjectContext?.perform { [self] in
                do {
                    encodedValue = try PropertyListSerialization.data(fromPropertyList: value, format: .xml, options: PropertyListSerialization.WriteOptions())
                } catch {
                    print("Failed to encoded property \(key) with value \(value)")
                }
//            }
        }
    }
    
    func hashChecksum(into hasher: inout Hasher) {
        key.hash(into: &hasher)
        encodedValue.hash(into: &hasher)
    }
}

extension CDProperty {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDProperty> {
        return NSFetchRequest<CDProperty>(entityName: "CDProperty")
    }
}
