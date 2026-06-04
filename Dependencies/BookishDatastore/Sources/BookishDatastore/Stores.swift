import BookishRecord
import Foundation

/// Stores materialised records.
public protocol RecordStore: Sendable {
  /// Returns a single record by identifier.
  func record(id: BookishRecordID) async throws -> BookishRecord?

  /// Returns all records in stable identifier order.
  func records() async throws -> [BookishRecord]

  /// Returns identifiers for records matching a predicate in stable identifier order.
  func recordIDs(matching predicate: RecordPredicate) async throws -> [BookishRecordID]

  /// Writes a materialised record.
  func upsert(_ record: BookishRecord) async throws

  /// Deletes a materialised record.
  func delete(id: BookishRecordID) async throws

  /// Removes every materialised record.
  func removeAll() async throws
}

/// Stores durable mutation records and applied state.
public protocol MutationStore: Sendable {
  /// Appends a new mutation if it has not already been stored.
  func append(_ mutation: MutationRecord) async throws

  /// Returns all stored mutations in creation order.
  func mutations() async throws -> [MutationRecord]

  /// Marks a mutation as applied to the projection.
  func markApplied(_ id: MutationID) async throws

  /// Returns whether a mutation has already been applied.
  func isApplied(_ id: MutationID) async throws -> Bool

  /// Removes every stored mutation and applied marker.
  func removeAll() async throws
}
