// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct InterchangeID {
    public init(id: String, name: String, kind: String) {
        self.id = id
        self.name = name
        self.kind = kind
    }
    
    public let id: String
    public let name: String
    public let kind: String
}

public struct InterchangeRecord {
    public init(_ id: InterchangeID) {
        self.id = id
        self.properties = [:]
        self.items = []
        self.links = []
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
}
