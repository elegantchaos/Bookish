import BookishRecord
import Foundation

/// Storage-neutral predicate for selecting records.
///
/// The shape intentionally mirrors SwiftData's predicate composition at a
/// domain level while remaining directly evaluable by the prototype JSON store.
public indirect enum RecordPredicate: Equatable, Sendable {
  /// Matches every record.
  case all

  /// Matches records with a specific identifier.
  case id(BookishRecordID)

  /// Matches records with a specific kind.
  case kind(String)

  /// Matches records whose materialised property exactly equals a value.
  case property(String, equals: BookishRecordValue)

  /// Matches records that satisfy every child predicate.
  case and([RecordPredicate])

  /// Matches records that satisfy at least one child predicate.
  case or([RecordPredicate])

  /// Matches records that do not satisfy the child predicate.
  case not(RecordPredicate)

  /// Returns whether the predicate accepts a materialised record.
  public func matches(_ record: BookishRecord) -> Bool {
    switch self {
    case .all:
      true

    case .id(let id):
      record.id == id

    case .kind(let kind):
      record.kind == kind

    case .property(let key, equals: let value):
      record.properties[key] == value

    case .and(let predicates):
      predicates.allSatisfy { $0.matches(record) }

    case .or(let predicates):
      predicates.contains { $0.matches(record) }

    case .not(let predicate):
      !predicate.matches(record)
    }
  }
}
