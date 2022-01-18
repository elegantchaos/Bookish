// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Bundles
import Foundation

public struct InterchangeCreator: Codable {
    public init(id: String, version: String, build: Int, commit: String) {
        self.id = id
        self.version = version
        self.build = build
        self.commit = commit
    }
    
    public init(_ info: BundleInfo) {
        self.id = info.id
        self.version = info.version.asString
        self.build = info.build
        self.commit = info.commit
    }
    
    public let id: String
    public let version: String
    public let build: Int
    public let commit: String
}
