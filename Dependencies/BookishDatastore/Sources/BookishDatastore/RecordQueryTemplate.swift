// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Foundation

/// Describes a record query that is resolved against a host record before execution.
///
/// Layout query sections store templates so relationship predicates can reference the
/// record currently being displayed while the query service receives a concrete query.
public struct RecordQueryTemplate: Codable, Equatable, Sendable {
  /// The concrete constraints that do not depend on the host record.
  public var query: RecordQuery

  /// Host-record relationship constraints appended to the base query.
  public var bindings: [RecordQueryBinding]

  /// Creates a template from a base query and optional host-record bindings.
  public init(query: RecordQuery, bindings: [RecordQueryBinding] = []) {
    self.query = query
    self.bindings = bindings
  }

  /// Resolves this template into a concrete query for the supplied host record.
  public func resolve(for host: BookishRecord) -> RecordQuery {
    RecordQuery(
      predicate: .and([query.predicate] + bindings.map { $0.predicate(for: host) }),
      sort: query.sort
    )
  }
}

/// A relationship predicate whose compared value is the displayed host record.
public enum RecordQueryBinding: Codable, Equatable, Sendable {
  /// Matches a scalar property linked to the host record.
  case propertyEqualsHostRecord(String)

  /// Matches a scalar or list property containing a link to the host record.
  case propertyContainsHostRecord(String)

  /// Resolves this binding into a concrete predicate for a host record.
  public func predicate(for host: BookishRecord) -> RecordPredicate {
    switch self {
    case .propertyEqualsHostRecord(let key):
      .property(key, equals: .record(host.id))

    case .propertyContainsHostRecord(let key):
      .propertyContains(key, .record(host.id))
    }
  }
}

extension RecordQueryBinding {
  private enum CodingKeys: String, CodingKey {
    case key
    case type
  }

  private enum Kind: String, Codable {
    case propertyEqualsHostRecord
    case propertyContainsHostRecord
  }

  /// Decodes a binding from its stable interchange representation.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let key = try container.decode(String.self, forKey: .key)

    switch try container.decode(Kind.self, forKey: .type) {
    case .propertyEqualsHostRecord:
      self = .propertyEqualsHostRecord(key)

    case .propertyContainsHostRecord:
      self = .propertyContainsHostRecord(key)
    }
  }

  /// Encodes a binding using its stable interchange representation.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .propertyEqualsHostRecord(let key):
      try container.encode(Kind.propertyEqualsHostRecord, forKey: .type)
      try container.encode(key, forKey: .key)

    case .propertyContainsHostRecord(let key):
      try container.encode(Kind.propertyContainsHostRecord, forKey: .type)
      try container.encode(key, forKey: .key)
    }
  }
}
