import BookishRecord
import Foundation

/// A display-ready representation of a datastore record for Bookish views.
public struct BookishRecordPresentation: Equatable, Sendable {
  /// The original datastore record being presented.
  public let record: BookishRecord

  /// The layout record used to choose labels and visible fields.
  public let layout: BookishRecord?

  /// Creates a presentation from a record and an optional layout record.
  public init(record: BookishRecord, layout: BookishRecord?) {
    self.record = record
    self.layout = layout
  }

  /// The title used for navigation, forms, and list rows.
  public var title: String {
    firstDisplayValue(for: [BookishRecordKey.title, BookishRecordKey.name]) ?? record.kind
  }

  /// The fields visible under the active layout.
  public var fields: [BookishRecordField] {
    fieldKeys.map { key in
      BookishRecordField(
        key: key,
        label: label(for: key),
        value: displayValue(for: key),
        rawValue: record.properties[key]
      )
    }
  }

  /// The user-facing name of the active layout.
  public var layoutTitle: String {
    layout?.string(BookishRecordKey.title) ?? "Default"
  }

  private var fieldKeys: [String] {
    guard
      let layoutFields = layout?.properties[BookishRecordKey.fields]?.listValue?.compactMap(
        \.stringValue),
      !layoutFields.isEmpty
    else {
      return record.properties.keys.sorted()
    }

    return expandedFieldKeys(layoutFields)
  }

  private func expandedFieldKeys(_ layoutFields: [String]) -> [String] {
    var included = Set<String>()
    var keys: [String] = []

    for key in layoutFields {
      if key == BookishRecordKey.allOtherFields {
        let remainingKeys = record.properties.keys
          .filter { !included.contains($0) }
          .sorted()
        keys.append(contentsOf: remainingKeys)
        included.formUnion(remainingKeys)
      } else if !included.contains(key) {
        keys.append(key)
        included.insert(key)
      }
    }

    return keys
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
public struct BookishRecordField: Equatable, Identifiable, Sendable {
  /// The datastore property key.
  public let key: String

  /// The display label derived from the property key.
  public let label: String

  /// The formatted property value.
  public let value: String

  /// The source record value, if the field exists on the record.
  public let rawValue: BookishRecordValue?

  /// Creates a display field.
  public init(
    key: String,
    label: String,
    value: String,
    rawValue: BookishRecordValue? = nil
  ) {
    self.key = key
    self.label = label
    self.value = value
    self.rawValue = rawValue
  }

  /// The stable identity for SwiftUI lists.
  public var id: String {
    key
  }
}

extension BookishRecordValue {
  /// Formats a Bookish property value for display.
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
    case .date(let value):
      value.formatted(date: .abbreviated, time: .omitted)
    case .record(let id):
      id.rawValue
    case .blob(let reference):
      reference.filename ?? reference.id
    case .list(let values):
      values.map(\.displayString).joined(separator: ", ")
    case .encoded(let value):
      value.keys.sorted().joined(separator: ", ")
    case .tombstone:
      "Tombstone"
    case .deletion:
      "Deleted"
    case .conflict(let values):
      values.map(\.displayString).joined(separator: " / ")
    }
  }
}
