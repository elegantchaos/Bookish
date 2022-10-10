// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public enum RecordKind: Int16, Identifiable, Codable {
    case unknown
    case root
    case group
    case list
    case book
    case role
    case link
    case person
    case organisation
    case series
    case importSession
    case merged
    
    public var id: Int16 { rawValue }
}
