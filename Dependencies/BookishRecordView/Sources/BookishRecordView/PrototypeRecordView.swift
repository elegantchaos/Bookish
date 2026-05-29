import BookishDatastore
import SwiftUI

/// Displays a record using a simple layout record.
public struct PrototypeRecordView: View {
  private let record: StoredRecord
  private let layout: StoredRecord

  /// Creates a record view from a data record and a layout record.
  public init(record: StoredRecord, layout: StoredRecord) {
    self.record = record
    self.layout = layout
  }

  public var body: some View {
    Form {
      Section {
        ForEach(fieldKeys, id: \.self) { key in
          LabeledContent(label(for: key)) {
            Text(displayValue(for: key))
              .textSelection(.enabled)
          }
        }
      } header: {
        Text(title)
      }
    }
    .formStyle(.grouped)
    .navigationTitle(title)
  }

  private var title: String {
    layout.string("title") ?? record.string("title") ?? record.kind
  }

  private var fieldKeys: [String] {
    layout.properties["fields"]?.listValue?.compactMap(\.stringValue)
      ?? record.properties.keys.sorted()
  }

  private func label(for key: String) -> String {
    key
      .replacingOccurrences(of: "_", with: " ")
      .capitalized
  }

  private func displayValue(for key: String) -> String {
    guard let value = record.properties[key] else {
      return ""
    }

    return value.displayString
  }
}

extension RecordPropertyValue {
  fileprivate var displayString: String {
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
