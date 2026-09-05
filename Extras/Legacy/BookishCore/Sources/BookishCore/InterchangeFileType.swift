// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct InterchangeFileType: Codable {
    public init(_ format: String, version: Int, variant: Variant = .normal) {
        self.format = format
        self.version = version
        self.variantName = variant == .normal ? nil : variant.rawValue
    }
    
    private enum CodingKeys: String, CodingKey {
        case format = "format"
        case version = "version"
        case variantName = "variant"
      }
    
    public enum Variant: String, Codable {
        case normal
        case compact
    }
    
    let format: String
    let version: Int
    let variantName: String?
    
    var variant: Variant {
        variantName.flatMap { Variant(rawValue: $0) } ?? .normal
    }
}
