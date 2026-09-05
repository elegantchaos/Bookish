// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct InterchangeID {
    public init(id: String, name: String, kind: String, checksum: Int) {
        self.id = id
        self.name = name
        self.kind = kind
        self.checksum = checksum
    }
    
    public init(_ raw: Any?) throws {
        guard
            let dictionary = raw as? [String:Any],
              let id = dictionary["id"] as? String,
            let name = dictionary["name"] as? String,
            let kind = dictionary["kind"] as? String,
            let checksum = dictionary["checksum"] as? Int
        else {
            throw InterchangeError.idDecodingFailed
        }
        
        self.id = id
        self.name = name
        self.kind = kind
        self.checksum = checksum
    }
    
    public let id: String
    public let name: String
    public let kind: String
    public let checksum: Int
    
    public var asDictionary: [String:Any] {
        return [
            "id": id,
            "name": name,
            "kind": kind,
            "checksum": checksum
        ]
    }
}
