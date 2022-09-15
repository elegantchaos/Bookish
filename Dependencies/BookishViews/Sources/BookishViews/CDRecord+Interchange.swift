// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCore
import JSONRepresentable

extension CDRecord {
    func checksum() -> Int {
        var hasher = Hasher()

        kind.hash(into: &hasher)
        name.hash(into: &hasher)
        for property in properties ?? [] {
            property.hashChecksum(into: &hasher)
        }
        for record in contents ?? [] {
            record.id.hash(into: &hasher)
        }
        return hasher.finalize()
    }
    
    func asInterchangeID() -> InterchangeID {
        return InterchangeID(id: id, name: name, kind: "\(kind)", checksum: checksum())
    }
    
    func asInterchange() -> InterchangeRecord {
        var encodedProperties: [String:Any] = [:]
        if let properties = properties {
            for property in properties {
                if let value = property.value as? JSONRepresentable {
                    encodedProperties[property.key] = value.asJSONType
                } else {
                    fatalError("can't encode key \(property.key): \(property.value) type: \(type(of: property.value))")
                }
            }
        }
        
        let items = contents?.map({ $0.asInterchangeID() }) ?? []
        let links = containedBy?.map({ $0.asInterchangeID() }) ?? []
        var record = InterchangeRecord(id: id, name: name, kind: "\(kind)", checksum: checksum())
        record.properties = encodedProperties
        record.items = items
        record.links = links
        
        return record
    }
    
}
