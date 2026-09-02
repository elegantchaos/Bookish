import BookishRecord
import Foundation

/// Stores materialised records.
public protocol RecordStore: Sendable {
  /// Returns a single record by identifier.
  func record(id: BookishRecordID) async throws -> BookishRecord?

  /// Returns all records in stable identifier order.
  func records() async throws -> [BookishRecord]

  /// Returns records matching a query in query sort order.
  func records(matching query: RecordQuery) async throws -> [BookishRecord]

  /// Returns identifiers for records matching a predicate in stable identifier order.
  func recordIDs(matching predicate: RecordPredicate) async throws -> [BookishRecordID]

  /// Writes a materialised record.
  func upsert(_ record: BookishRecord) async throws

  /// Deletes a materialised record.
  func delete(id: BookishRecordID) async throws

  /// Removes every materialised record.
  func removeAll() async throws
}
