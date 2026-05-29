import Foundation

/// Reads materialised records for application and UI clients.
public protocol RecordService: Sendable {
  /// Returns a single record by identifier.
  func record(id: RecordID) async throws -> StoredRecord?

  /// Returns all materialised records.
  func records() async throws -> [StoredRecord]

  /// Returns all materialised records matching a kind.
  func records(kind: String) async throws -> [StoredRecord]
}

/// Default prototype record service backed by a record store.
public struct DefaultRecordService<Store: RecordStore>: RecordService {
  private let store: Store

  /// Creates a record service.
  public init(store: Store) {
    self.store = store
  }

  /// Returns a single record by identifier.
  public func record(id: RecordID) async throws -> StoredRecord? {
    try await store.record(id: id)
  }

  /// Returns all materialised records.
  public func records() async throws -> [StoredRecord] {
    try await store.records()
  }

  /// Returns all materialised records matching a kind.
  public func records(kind: String) async throws -> [StoredRecord] {
    try await store.records().filter { $0.kind == kind }
  }
}
