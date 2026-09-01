import BookishRecord
import Foundation

/// Describes a supported local mutation operation.
public enum MutationOperation: Codable, Equatable, Sendable {
  /// Creates or replaces a complete record projection.
  case upsertRecord(BookishRecord)

  /// Sets one materialised property on an existing or newly-created record.
  case setProperty(recordID: BookishRecordID, kind: String, key: String, value: BookishRecordValue)

  /// Removes one materialised property from a record.
  case deleteProperty(recordID: BookishRecordID, key: String)

  /// Removes a materialised record.
  case deleteRecord(BookishRecordID)
}

/// A durable user or sync mutation.
public struct MutationRecord: Codable, Equatable, Identifiable, Sendable {
  /// The mutation's stable identity.
  public var id: MutationID

  /// The operation to apply.
  public var operation: MutationOperation

  /// The time the mutation was created.
  public var createdAt: Date

  /// Creates a mutation record.
  public init(id: MutationID = MutationID(), operation: MutationOperation, createdAt: Date = Date())
  {
    self.id = id
    self.operation = operation
    self.createdAt = createdAt
  }
}
