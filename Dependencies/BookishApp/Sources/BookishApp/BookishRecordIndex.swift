// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecord

/// A top-level browser index stored as a materialised record.
public struct BookishRecordIndex: Equatable, Identifiable, Sendable {
  /// The stored index record.
  public var record: BookishRecord

  /// The stable identity of the index record.
  public var id: BookishRecordID {
    record.id
  }

  /// The name shown in the top-level browser list.
  public var name: String {
    record.string(BookishRecordKey.name) ?? record.id.rawValue
  }

  /// The query used to populate the browser content column, when the stored payload is valid.
  public var query: RecordQuery? {
    record.encoded(BookishRecordKey.query)
  }

  /// Whether this index is intended only for debug or configuration browsing.
  public var isDebugOnly: Bool {
    record.bool(BookishRecordKey.debugOnly) ?? false
  }

  /// The layout to use when presenting records through this index.
  public var layoutID: BookishRecordID? {
    record.record(BookishRecordKey.layout)
  }

  /// The advisory record kinds that this index can surface.
  public var types: [String] {
    record.strings(BookishRecordKey.types) ?? []
  }

  /// Creates an index wrapper for a stored record.
  public init(record: BookishRecord) {
    self.record = record
  }

  /// Creates a stored index record.
  public static func record(
    id: BookishRecordID,
    name: String,
    position: Int,
    query: RecordQuery,
    types: [String] = [],
    debugOnly: Bool = false,
    layoutID: BookishRecordID? = nil,
    sourceID: String
  ) throws -> BookishRecord {
    var properties: [String: BookishRecordValue] = [
      BookishRecordKey.name: .string(name),
      BookishRecordKey.debugOnly: .bool(debugOnly),
      BookishRecordKey.position: .integer(position),
      BookishRecordKey.query: .encoded(try BookishEncodedValue(encoding: query)),
      BookishRecordKey.source: .string(sourceID),
    ]
    if !types.isEmpty {
      properties[BookishRecordKey.types] = .list(types.map(BookishRecordValue.string))
    }
    if let layoutID {
      properties[BookishRecordKey.layout] = .record(layoutID)
    }

    return BookishRecord(
      id: id,
      kind: BookishRecordKind.index,
      properties: properties
    )
  }
}
