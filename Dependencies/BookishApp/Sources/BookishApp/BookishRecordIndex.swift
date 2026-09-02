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

  /// The label shown in the top-level browser list.
  public var label: String {
    record.string(BookishRecordKey.label)
      ?? record.string(BookishRecordKey.title)
      ?? record.id.rawValue
  }

  /// The query used to populate the browser content column.
  public var query: RecordQuery {
    record.encoded(BookishRecordKey.query) ?? RecordQuery()
  }

  /// Creates an index wrapper for a stored record.
  public init(record: BookishRecord) {
    self.record = record
  }

  /// Creates a stored index record.
  public static func record(
    id: BookishRecordID,
    label: String,
    position: Int,
    query: RecordQuery,
    sourceID: String
  ) throws -> BookishRecord {
    BookishRecord(
      id: id,
      kind: BookishRecordKind.recordIndex,
      properties: [
        BookishRecordKey.label: .string(label),
        BookishRecordKey.position: .integer(position),
        BookishRecordKey.query: .encoded(try BookishEncodedValue(encoding: query)),
        BookishRecordKey.source: .string(sourceID),
      ]
    )
  }
}
