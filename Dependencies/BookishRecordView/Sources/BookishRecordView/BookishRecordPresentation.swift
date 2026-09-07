// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

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
      thumbnailURL: record.url(thumbnailProperty)
    )
  }

  /// The fields visible under the active layout while viewing a record.
  public var fields: [BookishRecordField] {
    fields(for: .viewing)
  }

  /// The ordered fields and query-section links visible under the active layout.
  public var layoutItems: [BookishRecordLayoutItem] {
    layoutItems(for: .viewing)
  }

  /// Returns the fields visible under the active layout for an interaction mode.
  public func fields(for mode: BookishValuePresentationMode) -> [BookishRecordField] {
    layoutItems(for: mode).compactMap { item in
      guard case .field(let field) = item else {
        return nil
      }

      return field
    }
  }

  /// Returns the ordered fields and query-section links for an interaction mode.
  public func layoutItems(for mode: BookishValuePresentationMode) -> [BookishRecordLayoutItem] {
    var includedFields = Set<String>()
    var items: [BookishRecordLayoutItem] = []

    for value in layoutValues {
      switch value {
      case .string(BookishRecordKey.allOtherFields):
        let remainingKeys = record.properties.keys
          .filter { !includedFields.contains($0) && !excludedFields.contains($0) }
          .sorted()
        items.append(contentsOf: remainingKeys.compactMap { field(for: $0, mode: mode) })
        includedFields.formUnion(remainingKeys)

      case .string(let key):
        guard !includedFields.contains(key), !excludedFields.contains(key) else {
          continue
        }
        includedFields.insert(key)
        if let field = field(for: key, mode: mode) {
          items.append(field)
        }

      case .record(let id):
        items.append(.section(id))

      default:
        continue
      }
    }

    return items
  }

  /// The user-facing name of the active layout.
  public var layoutName: String {
    layout?.string(BookishRecordKey.name) ?? "Default"
  }

  /// The ordered values declared in the active layout, or every record property by key.
  private var layoutValues: [BookishRecordValue] {
    guard let values = layout?.list(BookishRecordKey.fields), !values.isEmpty else {
      return record.properties.keys.sorted().map(BookishRecordValue.string)
    }

    return values
  }

  /// The property keys omitted from the active layout.
  private var excludedFields: Set<String> {
    Set(layout?.strings(BookishRecordKey.excludedFields) ?? [])
  }

  /// Builds a display field when the mode and presentation metadata permit it.
  private func field(for key: String, mode: BookishValuePresentationMode)
    -> BookishRecordLayoutItem?
  {
    let rawValue = record.properties[key]
    let propertyPresentation = propertyPresentation(for: key)
    guard mode == .editing || rawValue != nil || propertyPresentation?.alwaysShowViewer == true
    else {
      return nil
    }

    return .field(
      BookishRecordField(
        key: key,
        label: label(for: key),
        icon: propertyPresentation?.icon,
        viewer: propertyPresentation?.viewer,
        editor: propertyPresentation?.editor,
        value: displayValue(for: key),
        rawValue: rawValue
      ))
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
