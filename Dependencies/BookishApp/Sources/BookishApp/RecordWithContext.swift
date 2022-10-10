// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData

/// Link to a record, along with another optional record
/// which represents the context. Usually this will be a list
/// containing the record, that we navigated to it from.
public struct RecordWithContext {
    let record: CDRecord
    let context: CDRecord?
}

extension RecordWithContext: Hashable { } // To be used as a path component, needs to be Hashable.

// MARK: Debugging

extension RecordWithContext: CustomDebugStringConvertible {
    public var debugDescription: String {
        if let context {
            return "\(record) (in \(context)"
        } else {
            return "\(record)"
        }
    }
}

// MARK: Coding

extension CodingUserInfoKey {
    static let coreDataContextKey = CodingUserInfoKey(rawValue: "coreDataContext")!
}

extension RecordWithContext: Codable {
    struct CodedRepresentation: Codable {
        let id: String
        let context: String?
    }
    
    public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.coreDataContextKey] as? NSManagedObjectContext else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Missing CoreData Context"))
        }
        
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode(CodedRepresentation.self)
        
        guard let record = CDRecord.findWithID(decoded.id, in: context) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Record with id \(decoded.id) not found."))
        }

        self.record = record
        if let id = decoded.context {
            self.context = CDRecord.findWithID(id, in: context)
        } else {
            self.context = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(CodedRepresentation(id: record.id, context: context?.id))
    }
}
