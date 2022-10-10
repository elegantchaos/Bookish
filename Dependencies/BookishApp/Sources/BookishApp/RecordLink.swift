// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData

/// Link to a record, along with another optional record
/// which represents the source. Usually this will be a list
/// containing the record, that we navigated to it from.
public struct RecordLink {
    let record: CDRecord
    let source: CDRecord?
}

extension RecordLink: Hashable { } // To be used as a path component, needs to be Hashable.

// MARK: Debugging

extension RecordLink: CustomDebugStringConvertible {
    public var debugDescription: String {
        if let source {
            return "\(record) (in \(source)"
        } else {
            return "\(record)"
        }
    }
}

// MARK: Coding

extension CodingUserInfoKey {
    static let coreDataContextKey = CodingUserInfoKey(rawValue: "coreDataContext")!
}

extension RecordLink: Codable {
    struct CodedRepresentation: Codable {
        let id: String
        let source: String?
    }
    
    public init(from decoder: Decoder) throws {
        // We need a managed object context so that we can look up identifiers and turn them
        // back into CDRecord instances.
        guard let context = decoder.userInfo[.coreDataContextKey] as? NSManagedObjectContext else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Missing CoreData Context"))
        }
        
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode(CodedRepresentation.self)
        
        guard let record = CDRecord.findWithID(decoded.id, in: context) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Record with id \(decoded.id) not found."))
        }

        self.record = record
        if let id = decoded.source {
            self.source = CDRecord.findWithID(id, in: context)
        } else {
            self.source = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(CodedRepresentation(id: record.id, source: source?.id))
    }
}
