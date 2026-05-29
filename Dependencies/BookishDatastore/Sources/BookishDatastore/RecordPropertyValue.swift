import Foundation

/// A small, Codable property value model for the datastore proof of concept.
public enum RecordPropertyValue: Codable, Equatable, Sendable {
  /// A string property.
  case string(String)

  /// A whole-number property.
  case integer(Int)

  /// A floating-point property.
  case double(Double)

  /// A boolean property.
  case bool(Bool)

  /// A reference to another record.
  case record(RecordID)

  /// An ordered list of property values.
  case list([RecordPropertyValue])
}

extension RecordPropertyValue {
  /// Returns the contained string when this value is `.string`.
  public var stringValue: String? {
    guard case .string(let value) = self else {
      return nil
    }

    return value
  }

  /// Returns the contained list when this value is `.list`.
  public var listValue: [RecordPropertyValue]? {
    guard case .list(let value) = self else {
      return nil
    }

    return value
  }
}
