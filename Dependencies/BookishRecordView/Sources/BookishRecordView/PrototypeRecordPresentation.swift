import BookishDatastore
import Foundation

/// A display-ready representation of a datastore record for prototype views.
public struct PrototypeRecordPresentation: Equatable, Sendable {
  /// The original datastore record being presented.
  public let record: StoredRecord

  /// The layout record used to choose labels and visible fields.
  public let layout: StoredRecord?

  /// Creates a presentation from a record and an optional layout record.
  public init(record: StoredRecord, layout: StoredRecord?) {
    self.record = record
    self.layout = layout
  }

  /// The title used for navigation, forms, and list rows.
  public var title: String {
    firstDisplayValue(for: ["title", "name"]) ?? record.kind
  }

  /// The fields visible under the active layout.
  public var fields: [PrototypeRecordField] {
    fieldKeys.map { key in
      PrototypeRecordField(key: key, label: label(for: key), value: displayValue(for: key))
    }
  }

  /// The user-facing name of the active layout.
  public var layoutTitle: String {
    layout?.string("title") ?? "Default"
  }

  private var fieldKeys: [String] {
    guard let layoutFields = layout?.properties["fields"]?.listValue?.compactMap(\.stringValue),
      !layoutFields.isEmpty
    else {
      return record.properties.keys.sorted()
    }

    return layoutFields
  }

  private func label(for key: String) -> String {
    key
      .replacingOccurrences(of: "_", with: " ")
      .capitalized
  }

  private func displayValue(for key: String) -> String {
    record.properties[key]?.displayString ?? ""
  }

  private func firstDisplayValue(for keys: [String]) -> String? {
    keys.lazy.compactMap { key in
      let value = displayValue(for: key)
      return value.isEmpty ? nil : value
    }
    .first
  }
}

/// A single display-ready record field.
public struct PrototypeRecordField: Equatable, Identifiable, Sendable {
  /// The datastore property key.
  public let key: String

  /// The display label derived from the property key.
  public let label: String

  /// The formatted property value.
  public let value: String

  /// The stable identity for SwiftUI lists.
  public var id: String {
    key
  }
}

extension RecordPropertyValue {
  /// Formats a prototype property value for display.
  var displayString: String {
    switch self {
    case .string(let value):
      value
    case .integer(let value):
      value.formatted()
    case .double(let value):
      value.formatted()
    case .bool(let value):
      value ? "Yes" : "No"
    case .record(let id):
      id.rawValue
    case .list(let values):
      values.map(\.displayString).joined(separator: ", ")
    }
  }
}
