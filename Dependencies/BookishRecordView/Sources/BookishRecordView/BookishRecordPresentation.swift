import BookishRecord
import Foundation

/// A display-ready representation of a datastore record for Bookish views.
public struct BookishRecordPresentation: Equatable, Sendable {
  /// The original datastore record being presented.
  public let record: BookishRecord

  /// The layout record used to choose labels and visible fields.
  public let layout: BookishRecord?

  /// The presentation record used to present individual record properties.
  public let presentationRecord: BookishRecord?

  /// Creates a presentation from a record, an optional layout, and optional property metadata.
  public init(
    record: BookishRecord,
    layout: BookishRecord?,
    presentationRecord: BookishRecord? = nil
  ) {
    self.record = record
    self.layout = layout
    self.presentationRecord = presentationRecord
  }

  /// The name used for navigation, forms, and list rows.
  public var name: String {
    firstDisplayValue(for: [BookishRecordKey.name]) ?? record.kind
  }

  /// The fields visible under the active layout.
  public var fields: [BookishRecordField] {
    fieldKeys.map { key in
      BookishRecordField(
        key: key,
        label: label(for: key),
        icon: propertyPresentation(for: key)?.icon,
        value: displayValue(for: key),
        rawValue: record.properties[key]
      )
    }
  }

  /// The user-facing name of the active layout.
  public var layoutName: String {
    layout?.string(BookishRecordKey.name) ?? "Default"
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
    if let label = propertyPresentation(for: key)?.label {
      return label
    }

    return
      key
      .replacingOccurrences(of: "_", with: " ")
      .capitalized
  }

  private func propertyPresentation(for key: String) -> BookishPropertyPresentation? {
    presentationRecord?.encoded(key, as: BookishPropertyPresentation.self)
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

  /// The SF Symbol used to represent the property, when available.
  public let icon: String?

  /// The formatted property value.
  public let value: String

  /// The source record value, if the field exists on the record.
  public let rawValue: BookishRecordValue?

  /// Creates a display field.
  public init(
    key: String,
    label: String,
    icon: String? = nil,
    value: String,
    rawValue: BookishRecordValue? = nil
  ) {
    self.key = key
    self.label = label
    self.icon = icon
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
    if let date = dateValue {
      return date.formatted(date: .abbreviated, time: .omitted)
    }

    return switch self {
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
    case .blob(let reference):
      reference.filename ?? reference.id
    case .list(let values):
      values.map(\.displayString).joined(separator: ", ")
    case .encoded(let value, _):
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
