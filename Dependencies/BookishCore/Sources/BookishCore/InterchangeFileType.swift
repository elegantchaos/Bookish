// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct InterchangeFileType: Codable {
    public init(_ format: String, version: Int, variant: Variant = .normal) {
        self.format = format
        self.version = version
        self.variant = variant
    }
    
    public enum Variant: Codable {
        case normal
    }
    
    let format: String
    let version: Int
    let variant: Variant
}
