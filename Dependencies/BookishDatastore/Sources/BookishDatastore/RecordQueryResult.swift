// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Foundation
import Observation

/// Observable materialised records returned by a `RecordQueryService`.
@MainActor
@Observable
public final class RecordQueryResult {
  /// The query that defines this result.
  public private(set) var query: RecordQuery

  /// The ordered records currently matching the query.
  public private(set) var records: [BookishRecord]

  /// Increments when the records or error state changes.
  public private(set) var revision: Int

  /// The last refresh error, suitable for UI status text.
  public private(set) var errorDescription: String?

  /// Discards refreshes that finish after a newer store or mutation refresh.
  @ObservationIgnored private var latestRefreshVersion = 0

  /// Callbacks for clients that need to reconcile state after record changes.
  @ObservationIgnored private var recordsObservers: [UUID: @MainActor () -> Void] = [:]

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

  /// Registers a callback for changes to the ordered records.
  @discardableResult
  public func observeRecords(_ observer: @escaping @MainActor () -> Void) -> UUID {
    let token = UUID()
    recordsObservers[token] = observer
    return token
  }

  /// Removes a previously registered records callback.
  public func removeRecordsObserver(_ token: UUID) {
    recordsObservers.removeValue(forKey: token)
  }

  /// Replaces the result records after a successful refresh.
  public func update(records: [BookishRecord]) {
    guard self.records != records || errorDescription != nil else {
      return
    }

    publish(records: records)
  }

  func snapshot() -> (records: [BookishRecord], revision: Int) {
    (records, revision)
  }

  /// Publishes an actor-computed comparison against a particular observed revision.
  /// Returns false when another publication invalidated that comparison.
  @discardableResult
  func update(
    records: [BookishRecord], version: Int, comparedRevision: Int, unchanged: Bool
  ) -> Bool {
    guard version >= latestRefreshVersion else { return true }
    guard comparedRevision == revision else { return false }
    latestRefreshVersion = version
    if unchanged && errorDescription == nil { return true }
    publish(records: records)
    return true
  }

  private func publish(records: [BookishRecord]) {
    self.records = records
    errorDescription = nil
    revision += 1
    for observer in Array(recordsObservers.values) {
      observer()
    }
  }

  /// Records a failed refresh without dropping the last successful records.
  public func fail(error: Error) {
    let description = error.localizedDescription
    guard errorDescription != description else { return }
    errorDescription = description
    revision += 1
  }

  func fail(error: Error, version: Int) {
    guard version >= latestRefreshVersion else { return }
    latestRefreshVersion = version
    fail(error: error)
  }
}
