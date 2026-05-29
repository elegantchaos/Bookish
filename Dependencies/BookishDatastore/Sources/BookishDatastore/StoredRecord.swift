import Foundation

/// A materialised record stored by the prototype record store.
public struct StoredRecord: Codable, Equatable, Identifiable, Sendable {
  /// The record's stable identity.
  public var id: RecordID

  /// The application-level kind of record.
  public var kind: String

  /// The record's materialised properties.
  public var properties: [String: RecordPropertyValue]

  /// Creates a materialised record.
  public init(
    id: RecordID = RecordID(), kind: String, properties: [String: RecordPropertyValue] = [:]
  ) {
    self.id = id
    self.kind = kind
    self.properties = properties
  }

  /// Reads a string property by key.
  public func string(_ key: String) -> String? {
    properties[key]?.stringValue
  }
}
