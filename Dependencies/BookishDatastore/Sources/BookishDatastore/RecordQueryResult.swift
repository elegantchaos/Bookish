// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Observation

/// Observable materialised records returned by a `RecordQueryService`.
@MainActor
@Observable
public final class RecordQueryResult: @unchecked Sendable {
  /// The query that defines this result.
  public private(set) var query: RecordQuery

  /// The ordered records currently matching the query.
  public private(set) var records: [BookishRecord]

  /// Increments when the records or error state changes.
  public private(set) var revision: Int

  /// The last refresh error, suitable for UI status text.
  public private(set) var errorDescription: String?

  /// The ordered identifiers currently matching the query.
  public var ids: [BookishRecordID] {
    records.map(\.id)
  }

  /// Creates an empty observable result for a query.
  public init(query: RecordQuery) {
    self.query = query
    self.records = []
    self.revision = 0
    self.errorDescription = nil
  }

  /// Returns whether this result represents a query.
  public func matches(_ query: RecordQuery) -> Bool {
    self.query == query
  }

  /// Replaces the result records after a successful refresh.
  public func update(records: [BookishRecord]) {
    guard self.records != records || errorDescription != nil else {
      return
    }

    self.records = records
    errorDescription = nil
    revision += 1
  }

  /// Records a failed refresh without dropping the last successful records.
  public func fail(error: Error) {
    errorDescription = error.localizedDescription
    revision += 1
  }
}
