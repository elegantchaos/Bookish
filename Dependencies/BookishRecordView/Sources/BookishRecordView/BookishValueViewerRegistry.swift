import BookishRecord
import SwiftUI

/// Chooses and builds views for record field values.
@MainActor
public struct BookishValueViewerRegistry {
  /// A view builder that makes a record reference navigable when navigation is available.
  public typealias RecordLinkView = (BookishRecordID) -> AnyView

  private let recordLinkView: RecordLinkView?

  /// Creates a registry with an optional application-specific record navigation view.
  public init(recordLinkView: RecordLinkView? = nil) {
    self.recordLinkView = recordLinkView
  }

  /// Returns the effective component identifier for a field in an interaction mode.
  public func identifier(for field: BookishRecordField, mode: BookishValuePresentationMode)
    -> String
  {
    switch mode {
    case .viewing:
      field.viewer ?? nativeIdentifier(for: field.rawValue)
    case .editing:
      field.editor ?? nativeEditorIdentifier(for: field.rawValue)
    }
  }

  /// Builds the component selected for a field, safely falling back to a textual value.
  public func view(for field: BookishRecordField, mode: BookishValuePresentationMode) -> AnyView {
    switch identifier(for: field, mode: mode) {
    case "list", "record.linkList":
      if let values = field.rawValue?.listValue {
        return AnyView(BookishListValueView(values: values, registry: self, mode: mode))
      }
    case "presentation":
      if let presentation = propertyPresentation(from: field.rawValue) {
        return AnyView(BookishPropertyPresentationValueView(presentation: presentation))
      }
    case "record.link":
      if let recordID = field.rawValue?.recordValue, let recordLinkView {
        return recordLinkView(recordID)
      }
    default:
      break
    }

    return AnyView(Text(field.value).textSelection(.enabled))
  }

  private func nativeIdentifier(for value: BookishRecordValue?) -> String {
    switch value {
    case .list:
      "list"
    case .record:
      "record.link"
    case .encoded(let encoded, _):
      (try? encoded.decode(BookishPropertyPresentation.self)) == nil ? "text" : "presentation"
    default:
      "text"
    }
  }

  private func nativeEditorIdentifier(for value: BookishRecordValue?) -> String {
    switch value {
    case .integer:
      "integer.stepper"
    case .bool:
      "bool.toggle"
    default:
      nativeIdentifier(for: value)
    }
  }

  private func propertyPresentation(
    from value: BookishRecordValue?
  ) -> BookishPropertyPresentation? {
    guard let encoded = value?.encodedValue else {
      return nil
    }

    return try? encoded.decode(BookishPropertyPresentation.self)
  }
}

/// Displays an ordered property-value list with one viewer per item.
private struct BookishListValueView: View {
  let values: [BookishRecordValue]
  let registry: BookishValueViewerRegistry
  let mode: BookishValuePresentationMode

  var body: some View {
    VStack(alignment: .leading) {
      ForEach(Array(values.enumerated()), id: \.offset) { offset, value in
        registry.view(for: field(for: value, at: offset), mode: mode)
      }
    }
  }

  private func field(for value: BookishRecordValue, at offset: Int) -> BookishRecordField {
    BookishRecordField(
      key: "item-\(offset)", label: "Item \(offset + 1)", value: value.displayString,
      rawValue: value)
  }
}

/// Displays the individual members of property-presentation metadata.
private struct BookishPropertyPresentationValueView: View {
  let presentation: BookishPropertyPresentation

  var body: some View {
    Grid(alignment: .leading, verticalSpacing: 4) {
      field("Icon", value: presentation.icon)
      field("Label", value: presentation.label)
      field("Viewer", value: presentation.viewer)
      field("Editor", value: presentation.editor)
    }
    .font(.subheadline)
  }

  @ViewBuilder
  private func field(_ label: String, value: String?) -> some View {
    GridRow {
      Text(label)
        .foregroundStyle(.secondary)
      Text(value ?? "—")
        .textSelection(.enabled)
    }
  }
}
