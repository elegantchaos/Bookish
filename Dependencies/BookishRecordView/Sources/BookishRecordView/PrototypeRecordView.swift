import BookishRecord
import SwiftUI

/// Displays a record using a simple layout record.
public struct PrototypeRecordView: View {
  private let presentation: PrototypeRecordPresentation
  private let customValueView: @MainActor (PrototypeRecordField) -> AnyView?

  /// Creates a record view from a data record and a layout record.
  public init(
    record: BookishRecord,
    layout: BookishRecord,
    customValueView: @escaping @MainActor (PrototypeRecordField) -> AnyView? = { _ in nil }
  ) {
    self.init(record: record, layout: Optional(layout), customValueView: customValueView)
  }

  /// Creates a record view from a data record and an optional layout record.
  public init(
    record: BookishRecord,
    layout: BookishRecord?,
    customValueView: @escaping @MainActor (PrototypeRecordField) -> AnyView? = { _ in nil }
  ) {
    self.presentation = PrototypeRecordPresentation(record: record, layout: layout)
    self.customValueView = customValueView
  }

  /// The SwiftUI content for the record detail view.
  public var body: some View {
    Form {
      Section {
        ForEach(presentation.fields) { field in
          LabeledContent(field.label) {
            if let customView = customValueView(field) {
              customView
            } else {
              Text(field.value)
                .textSelection(.enabled)
            }
          }
        }
      } header: {
        Text(presentation.layoutTitle)
      }
    }
    .formStyle(.grouped)
    .navigationTitle(presentation.title)
  }
}

#Preview {
  NavigationStack {
    PrototypeRecordView(
      record: BookishRecord(
        id: BookishRecordID("book-preview"),
        kind: "book",
        properties: [
          "title": .string("The Left Hand of Darkness"),
          "author": .string("Ursula K. Le Guin"),
          "status": .string("To Read"),
        ]
      ),
      layout: BookishRecord(
        id: BookishRecordID("layout-preview"),
        kind: "layout",
        properties: [
          "title": .string("Book"),
          "fields": .list([.string("title"), .string("author"), .string("status")]),
        ]
      )
    )
  }
}
