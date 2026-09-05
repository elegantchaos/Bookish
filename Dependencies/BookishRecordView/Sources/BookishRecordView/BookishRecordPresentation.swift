import BookishRecord
import Foundation

/// A display-ready representation of a datastore record for Bookish views.
public struct BookishRecordPresentation: Sendable {
  /// The original datastore record being presented.
  public let record: BookishRecord

  /// The layout record used to choose labels and visible fields.
  public let layout: BookishRecord?

  /// The resolver used to find property presentation metadata.
  public let presentationResolver: any PresentationResolver

  /// Creates a presentation from a record, an optional layout, and a property metadata resolver.
  public init(
    record: BookishRecord,
    layout: BookishRecord?,
    presentationResolver: any PresentationResolver = CascadingPresentationResolver()
  ) {
    self.record = record
    self.layout = layout
    self.presentationResolver = presentationResolver
  }

  /// The name used for navigation, forms, and list rows.
  public var name: String {
    firstDisplayValue(for: [BookishRecordKey.name]) ?? record.kind
  }

  /// The title, subtitle, and thumbnail configured by the active layout.
  public var header: BookishRecordHeader {
    let titleProperty = headerProperty(
      BookishRecordKey.titleProperty, default: BookishRecordKey.name)
    let subtitleProperty = headerProperty(
      BookishRecordKey.subtitleProperty, default: BookishRecordKey.subtitle)
    let thumbnailProperty = headerProperty(
      BookishRecordKey.thumbnailProperty, default: BookishRecordKey.image)

    return BookishRecordHeader(
      title: record.string(titleProperty),
      subtitle: record.string(subtitleProperty),
      thumbnailURL: record.string(thumbnailProperty).flatMap(URL.init(string:))
    )
  }

  /// The fields visible under the active layout while viewing a record.
  public var fields: [BookishRecordField] {
    fields(for: .viewing)
  }

  /// Returns the fields visible under the active layout for an interaction mode.
  public func fields(for mode: BookishValuePresentationMode) -> [BookishRecordField] {
    fieldKeys.compactMap { key in
      let rawValue = record.properties[key]
      let propertyPresentation = propertyPresentation(for: key)
      guard mode == .editing || rawValue != nil || propertyPresentation?.alwaysShowViewer == true
      else {
        return nil
      }

      return BookishRecordField(
        key: key,
        label: label(for: key),
        icon: propertyPresentation?.icon,
        viewer: propertyPresentation?.viewer,
        editor: propertyPresentation?.editor,
        value: displayValue(for: key),
        rawValue: rawValue
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

    let excludedKeys = Set(
      layout?.properties[BookishRecordKey.excludedFields]?.listValue?.compactMap(\.stringValue)
        ?? [])
    return expandedFieldKeys(layoutFields).filter { excludedKeys.contains($0) == false }
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
    presentationResolver.presentation(for: key)
  }

  private func headerProperty(_ overrideKey: String, default defaultKey: String) -> String {
    layout?.string(overrideKey) ?? defaultKey
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

/// The interaction mode used to select value components and visible fields.
public enum BookishValuePresentationMode: Sendable {
  /// Displays only values present on the record.
  case viewing

  /// Displays every field supplied by the active layout so values can be added.
  case editing
}

/// A single display-ready record field.
public struct BookishRecordField: Equatable, Identifiable, Sendable {
  /// The datastore property key.
  public let key: String

  /// The display label derived from the property key.
  public let label: String

  /// The SF Symbol used to represent the property, when available.
  public let icon: String?

  /// The stable identifier of the preferred value viewer, when configured.
  public let viewer: String?

  /// The stable identifier of the preferred value editor, when configured.
  public let editor: String?

  /// The formatted property value.
  public let value: String

  /// The source record value, if the field exists on the record.
  public let rawValue: BookishRecordValue?

  /// Creates a display field.
  public init(
    key: String,
    label: String,
    icon: String? = nil,
    viewer: String? = nil,
    editor: String? = nil,
    value: String,
    rawValue: BookishRecordValue? = nil
  ) {
    self.key = key
    self.label = label
    self.icon = icon
    self.viewer = viewer
    self.editor = editor
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
