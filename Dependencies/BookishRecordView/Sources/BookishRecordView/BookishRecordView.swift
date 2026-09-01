import BookishRecord
import SwiftUI

/// Displays a record using a simple layout record.
public struct BookishRecordView: View {
  private let presentation: BookishRecordPresentation
  private let customValueView: @MainActor (BookishRecordField) -> AnyView?

  /// Creates a record view from a data record and a layout record.
  public init(
    record: BookishRecord,
    layout: BookishRecord,
    customValueView: @escaping @MainActor (BookishRecordField) -> AnyView? = { _ in nil }
  ) {
    self.init(record: record, layout: Optional(layout), customValueView: customValueView)
  }

  /// Creates a record view from a data record and an optional layout record.
  public init(
    record: BookishRecord,
    layout: BookishRecord?,
    customValueView: @escaping @MainActor (BookishRecordField) -> AnyView? = { _ in nil }
  ) {
    self.presentation = BookishRecordPresentation(record: record, layout: layout)
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
    BookishRecordView(
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
