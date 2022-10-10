// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData

/// Item that can be stored in a NavigationPath, to represent a record.
/// In memory we pass around CDRecords directly.
/// When the path is encoded to persist it, we convert these to identifiers.
/// When the path is later decoded, we always get back identifiers.
/// During decoding the core data stack may not yet be set up, so resolving the
/// identifiers into objects is deferred until they are actually used.
enum RecordPath {
    case objects(RecordWithContext)
    case ids(RecordIDWithContext)
    
    public func resolve(withContext context: NSManagedObjectContext) -> RecordWithContext? {
        switch self {
            case .objects(let value): return value
            case .ids(let ids): return RecordWithContext(ids, context: context)
        }
    }
    
    public init(record: CDRecord, context: CDRecord?) {
        self = .objects(.init(record: record, context: context))
    }
    
    /// Convert to identifiers.
    /// We always compare, hash, and encode in this form.
    public var asIdentifiers: RecordIDWithContext {
        switch self {
            case .objects(let value):
                return RecordIDWithContext(record: value.record.id, context: value.context?.id)
            case .ids(let value):
                return value
        }
    }
    

}

extension RecordPath: Equatable {
    static func == (lhs: RecordPath, rhs: RecordPath) -> Bool {
        lhs.asIdentifiers == rhs.asIdentifiers
    }
}

extension RecordPath: Hashable {
    func hash(into hasher: inout Hasher) {
        asIdentifiers.hash(into: &hasher)
    }
}

extension RecordPath: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode(RecordIDWithContext.self)
        print("decoded \(decoded)")
        self = .ids(decoded)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(asIdentifiers)
    }
}

/// Link to a record, along with another optional record
/// which represents the context. Usually this will be a list
/// containing the record, that we navigated to it from.
public struct RecordWithContext {
    internal init(record: CDRecord, context: CDRecord? = nil) {
        self.record = record
        self.context = context
    }
    
    let record: CDRecord
    let context: CDRecord?
    
    init?(_ ids: RecordIDWithContext, context managedObjectContext: NSManagedObjectContext) {
        guard let record = CDRecord.findWithID(ids.record, in: managedObjectContext) else { return nil }
        
        self.record = record
        if let id = ids.context, let resolved = CDRecord.findWithID(id, in: managedObjectContext) {
            self.context = resolved
        } else {
            self.context = nil
        }
        
    }
}

extension RecordWithContext: CustomDebugStringConvertible {
    public var debugDescription: String {
        if let context {
            return "\(record) (in \(context)"
        } else {
            return "\(record)"
        }
    }
}

/// Link to a record, along with another option record,
/// encoded as identifiers.
public struct RecordIDWithContext: Codable, Hashable {
    let record: String
    let context: String?
}

extension RecordIDWithContext: CustomDebugStringConvertible {
    public var debugDescription: String {
        if let context {
            return "<record \(record)> (in <record \(context)>"
        } else {
            return "<record \(record)>"
        }
    }
}
