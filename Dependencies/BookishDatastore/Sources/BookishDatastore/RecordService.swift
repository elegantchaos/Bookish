import BookishRecord
import Foundation

/// Reads materialised records for application and UI clients.
public protocol RecordService: Sendable {
  /// Returns a single record by identifier.
  func record(id: BookishRecordID) async throws -> BookishRecord?

  /// Returns all materialised records.
  func records() async throws -> [BookishRecord]

  /// Returns identifiers for all materialised records.
  func recordIDs() async throws -> [BookishRecordID]

  /// Returns identifiers for materialised records matching a predicate.
  func recordIDs(matching predicate: RecordPredicate) async throws -> [BookishRecordID]

  /// Returns all materialised records matching a kind.
  func records(kind: String) async throws -> [BookishRecord]
}

/// Default prototype record service backed by a record store.
public struct DefaultRecordService<Store: RecordStore>: RecordService {
  private let store: Store

  /// Creates a record service.
  public init(store: Store) {
    self.store = store
  }

  /// Returns a single record by identifier.
  public func record(id: BookishRecordID) async throws -> BookishRecord? {
    try await store.record(id: id)
  }

  /// Returns all materialised records.
  public func records() async throws -> [BookishRecord] {
    try await store.records()
  }

  /// Returns identifiers for all materialised records.
  public func recordIDs() async throws -> [BookishRecordID] {
    try await recordIDs(matching: .all)
  }

  /// Returns identifiers for materialised records matching a predicate.
  public func recordIDs(matching predicate: RecordPredicate) async throws -> [BookishRecordID] {
    try await store.recordIDs(matching: predicate)
  }

  /// Returns all materialised records matching a kind.
  public func records(kind: String) async throws -> [BookishRecord] {
    let ids = try await recordIDs(matching: .kind(kind))
    var records: [BookishRecord] = []
    for id in ids {
      if let record = try await record(id: id) {
        records.append(record)
      }
    }
    return records
  }
}
