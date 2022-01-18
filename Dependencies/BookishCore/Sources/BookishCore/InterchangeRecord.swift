// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct InterchangeRecord {
    public init(_ id: InterchangeID) {
        self.id = id
        self.properties = [:]
        self.items = []
        self.links = []
    }
    
    public init(_ raw: Any?) throws {
        guard
            let dictionary = raw as? [String:Any],
            let properties = dictionary["properties"] as? [String:Any],
            let items = dictionary["items"] as? [InterchangeID],
            let links = dictionary["links"] as? [InterchangeID]
        else {
            throw InterchangeError.recordDecodingFailed
        }

        self.id = try InterchangeID(dictionary["id"])

        self.properties = properties
        self.items = items
        self.links = links
    }
    
    public init(id: String, name: String, kind: String) {
        self.id = InterchangeID(id: id, name: name, kind: kind)
        self.properties = [:]
        self.items = []
        self.links = []
    }
    
    public let id: InterchangeID
    public var properties: [String:Any]
    public var items: [InterchangeID]
    public var links: [InterchangeID]
    
    public var asDictionary: [String:Any] {
        var dictionary = properties
        dictionary.merge(id.asDictionary, uniquingKeysWith: { l, r in r })
        dictionary["items"] = items.map { $0.asDictionary }
        dictionary["links"] = items.map { $0.asDictionary }
        return dictionary
    }
    
    public subscript(key: String) -> Any? {
        get { return properties[key] }
        set { properties[key] = newValue }
    }
}
