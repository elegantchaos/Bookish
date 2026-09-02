import BookishRecord
import Foundation

/// Storage-neutral predicate for selecting records.
///
/// The shape intentionally mirrors SwiftData's predicate composition at a
/// domain level while remaining directly evaluable by the local JSON store.
public indirect enum RecordPredicate: Codable, Equatable, Sendable {
  /// Matches every record.
  case all

  /// Matches records with a specific identifier.
  case id(BookishRecordID)

  /// Matches records with a specific kind.
  case kind(String)

  /// Matches records whose materialised property exactly equals a value.
  case property(String, equals: BookishRecordValue)

  /// Matches records whose materialised property is, or contains, a value.
  case propertyContains(String, BookishRecordValue)

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

    case .propertyContains(let key, let value):
      switch record.properties[key] {
      case .list(let values):
        values.contains(value)

      case .some(let candidate):
        candidate == value

      case .none:
        false
      }

    case .and(let predicates):
      predicates.allSatisfy { $0.matches(record) }

    case .or(let predicates):
      predicates.contains { $0.matches(record) }

    case .not(let predicate):
      !predicate.matches(record)
    }
  }
}

extension RecordPredicate {
  private enum CodingKeys: String, CodingKey {
    case key
    case kind
    case predicate
    case predicates
    case type
    case value
  }

  private enum Kind: String, Codable {
    case all
    case id
    case kind
    case property
    case propertyContains
    case and
    case or
    case not
  }

  /// Creates a predicate from its stable stored representation.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(Kind.self, forKey: .type)

    switch type {
    case .all:
      self = .all

    case .id:
      self = .id(try container.decode(BookishRecordID.self, forKey: .value))

    case .kind:
      self = .kind(try container.decode(String.self, forKey: .kind))

    case .property:
      self = .property(
        try container.decode(String.self, forKey: .key),
        equals: try container.decode(BookishRecordValue.self, forKey: .value)
      )

    case .propertyContains:
      self = .propertyContains(
        try container.decode(String.self, forKey: .key),
        try container.decode(BookishRecordValue.self, forKey: .value)
      )

    case .and:
      self = .and(try container.decode([RecordPredicate].self, forKey: .predicates))

    case .or:
      self = .or(try container.decode([RecordPredicate].self, forKey: .predicates))

    case .not:
      self = .not(try container.decode(RecordPredicate.self, forKey: .predicate))
    }
  }

  /// Encodes this predicate into its stable stored representation.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .all:
      try container.encode(Kind.all, forKey: .type)

    case .id(let id):
      try container.encode(Kind.id, forKey: .type)
      try container.encode(id, forKey: .value)

    case .kind(let kind):
      try container.encode(Kind.kind, forKey: .type)
      try container.encode(kind, forKey: .kind)

    case .property(let key, equals: let value):
      try container.encode(Kind.property, forKey: .type)
      try container.encode(key, forKey: .key)
      try container.encode(value, forKey: .value)

    case .propertyContains(let key, let value):
      try container.encode(Kind.propertyContains, forKey: .type)
      try container.encode(key, forKey: .key)
      try container.encode(value, forKey: .value)

    case .and(let predicates):
      try container.encode(Kind.and, forKey: .type)
      try container.encode(predicates, forKey: .predicates)

    case .or(let predicates):
      try container.encode(Kind.or, forKey: .type)
      try container.encode(predicates, forKey: .predicates)

    case .not(let predicate):
      try container.encode(Kind.not, forKey: .type)
      try container.encode(predicate, forKey: .predicate)
    }
  }
}
