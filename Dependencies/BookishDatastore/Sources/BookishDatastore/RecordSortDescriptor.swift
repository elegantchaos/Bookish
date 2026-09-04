// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Foundation

/// The direction used by a record sort descriptor.
public enum RecordSortDirection: Codable, Equatable, Sendable {
  /// Sorts lower values before higher values.
  case ascending

  /// Sorts higher values before lower values.
  case descending
}

extension RecordSortDirection {
  /// Creates a sort direction from its stable stored representation.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(String.self)

    switch value {
    case "ascending":
      self = .ascending

    case "descending":
      self = .descending

    default:
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unknown record sort direction '\(value)'."
      )
    }
  }

  /// Encodes this sort direction into its stable stored representation.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .ascending:
      try container.encode("ascending")

    case .descending:
      try container.encode("descending")
    }
  }
}

/// A storage-neutral sort descriptor for materialised records.
public struct RecordSortDescriptor: Codable, Equatable, Sendable {
  /// Sorts by stable record identifier.
  public static let id = RecordSortDescriptor(key: .id)

  /// Sorts by application-level record kind.
  public static let kind = RecordSortDescriptor(key: .kind)

  /// The record field used by this descriptor.
  public var key: RecordSortKey

  /// The direction used by this descriptor.
  public var direction: RecordSortDirection

  /// Creates a sort descriptor.
  public init(
    key: RecordSortKey,
    direction: RecordSortDirection = .ascending
  ) {
    self.key = key
    self.direction = direction
  }

  /// Sorts by a materialised record property.
  public static func property(
    _ key: String,
    direction: RecordSortDirection = .ascending
  ) -> RecordSortDescriptor {
    RecordSortDescriptor(key: .property(key), direction: direction)
  }

  /// Compares two records using this descriptor.
  public func compare(_ lhs: BookishRecord, _ rhs: BookishRecord) -> ComparisonResult {
    let comparison =
      switch key {
      case .id:
        lhs.id.rawValue.localizedStandardCompare(rhs.id.rawValue)

      case .kind:
        lhs.kind.localizedStandardCompare(rhs.kind)

      case .property(let key):
        compare(lhs.properties[key], rhs.properties[key])
      }

    switch direction {
    case .ascending:
      return comparison

    case .descending:
      return comparison.reversed
    }
  }

  private func compare(
    _ lhs: BookishRecordValue?,
    _ rhs: BookishRecordValue?
  ) -> ComparisonResult {
    switch (lhs, rhs) {
    case (.none, .none):
      return .orderedSame

    case (.none, .some):
      return .orderedDescending

    case (.some, .none):
      return .orderedAscending

    case (.some(let lhs), .some(let rhs)):
      return compare(lhs, rhs)
    }
  }

  private func compare(
    _ lhs: BookishRecordValue,
    _ rhs: BookishRecordValue
  ) -> ComparisonResult {
    if let lhsDate = lhs.dateValue, let rhsDate = rhs.dateValue {
      return lhsDate.comparisonResult(with: rhsDate)
    }

    switch (lhs, rhs) {
    case (.string(let lhs), .string(let rhs)):
      return lhs.localizedStandardCompare(rhs)

    case (.integer(let lhs), .integer(let rhs)):
      return lhs.comparisonResult(with: rhs)

    case (.double(let lhs), .double(let rhs)):
      return lhs.comparisonResult(with: rhs)

    case (.bool(let lhs), .bool(let rhs)):
      return lhs == rhs ? .orderedSame : (lhs ? .orderedDescending : .orderedAscending)

    case (.record(let lhs), .record(let rhs)):
      return lhs.rawValue.localizedStandardCompare(rhs.rawValue)

    case (.list(let lhs), .list(let rhs)):
      return compareLists(lhs, rhs)

    default:
      return String(describing: lhs).localizedStandardCompare(String(describing: rhs))
    }
  }

  private func compareLists(
    _ lhs: [BookishRecordValue],
    _ rhs: [BookishRecordValue]
  ) -> ComparisonResult {
    for index in 0..<min(lhs.count, rhs.count) {
      let comparison = compare(lhs[index], rhs[index])
      if comparison != .orderedSame {
        return comparison
      }
    }

    return lhs.count.comparisonResult(with: rhs.count)
  }
}

/// A field that can be used by a record sort descriptor.
public enum RecordSortKey: Codable, Equatable, Sendable {
  /// The stable record identifier.
  case id

  /// The application-level record kind.
  case kind

  /// A materialised property value.
  case property(String)
}

extension RecordSortKey {
  private enum CodingKeys: String, CodingKey {
    case key
    case type
  }

  private enum Kind: String, Codable {
    case id
    case kind
    case property
  }

  /// Creates a sort key from its stable stored representation.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(Kind.self, forKey: .type)

    switch type {
    case .id:
      self = .id

    case .kind:
      self = .kind

    case .property:
      self = .property(try container.decode(String.self, forKey: .key))
    }
  }

  /// Encodes this sort key into its stable stored representation.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .id:
      try container.encode(Kind.id, forKey: .type)

    case .kind:
      try container.encode(Kind.kind, forKey: .type)

    case .property(let key):
      try container.encode(Kind.property, forKey: .type)
      try container.encode(key, forKey: .key)
    }
  }
}

extension Comparable {
  /// Returns a Foundation comparison result for two comparable values.
  fileprivate func comparisonResult(with other: Self) -> ComparisonResult {
    if self < other {
      return .orderedAscending
    }

    if self > other {
      return .orderedDescending
    }

    return .orderedSame
  }
}

extension ComparisonResult {
  /// Returns the opposite ordering.
  fileprivate var reversed: ComparisonResult {
    switch self {
    case .orderedAscending:
      return .orderedDescending

    case .orderedDescending:
      return .orderedAscending

    case .orderedSame:
      return .orderedSame
    }
  }
}
