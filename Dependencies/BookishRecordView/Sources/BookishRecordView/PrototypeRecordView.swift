import BookishDatastore
import SwiftUI

/// Displays a record using a simple layout record.
public struct PrototypeRecordView: View {
  private let presentation: PrototypeRecordPresentation

  /// Creates a record view from a data record and a layout record.
  public init(record: StoredRecord, layout: StoredRecord) {
    self.init(record: record, layout: Optional(layout))
  }

  /// Creates a record view from a data record and an optional layout record.
  public init(record: StoredRecord, layout: StoredRecord?) {
    self.presentation = PrototypeRecordPresentation(record: record, layout: layout)
  }

  /// The SwiftUI content for the record detail view.
  public var body: some View {
    Form {
      Section {
        ForEach(presentation.fields) { field in
          LabeledContent(field.label) {
            Text(field.value)
              .textSelection(.enabled)
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
      record: StoredRecord(
        id: RecordID("book-preview"),
        kind: "book",
        properties: [
          "title": .string("The Left Hand of Darkness"),
          "author": .string("Ursula K. Le Guin"),
          "status": .string("To Read"),
        ]
      ),
      layout: StoredRecord(
        id: RecordID("layout-preview"),
        kind: "layout",
        properties: [
          "title": .string("Book"),
          "fields": .list([.string("title"), .string("author"), .string("status")]),
        ]
      )
    )
  }
}
