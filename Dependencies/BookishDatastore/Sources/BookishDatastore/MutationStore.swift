import BookishRecord
import Foundation

/// Stores durable mutation records and applied state.
public protocol MutationStore: Sendable {
  /// Appends a new mutation if it has not already been stored.
  func append(_ mutation: MutationRecord) async throws

  /// Returns all stored mutations in creation order.
  func mutations() async throws -> [MutationRecord]

  /// Returns a creation date for a new local mutation.
  ///
  /// Each date is later than every previously issued date and every stored mutation's
  /// creation date, so local mutations sort after everything this store has seen, even if
  /// the wall clock steps backwards.
  func nextCreationDate() async throws -> Date

  /// Marks a mutation as applied to the projection.
  func markApplied(_ id: MutationID) async throws

  /// Returns whether a mutation has already been applied.
  func isApplied(_ id: MutationID) async throws -> Bool

  /// Removes all applied markers so the mutation history can rebuild a projection.
  func removeAppliedMarkers() async throws

  /// Removes every stored mutation and applied marker.
  func removeAll() async throws
}
