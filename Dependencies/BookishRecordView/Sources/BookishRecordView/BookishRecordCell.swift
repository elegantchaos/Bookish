import BookishRecord
import SwiftUI

/// A compact row view for displaying a datastore record in an index.
public struct BookishRecordCell: View {
  private let presentation: BookishRecordPresentation

  /// Creates a row view from a data record and an optional layout record.
  public init(record: BookishRecord, layout: BookishRecord?) {
    self.presentation = BookishRecordPresentation(record: record, layout: layout)
  }

  /// The SwiftUI content for the row.
  public var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Text(presentation.title)
          .font(.headline)
        Spacer()
        Text(presentation.record.kind)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(summary)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }

  private var summary: String {
    let values = presentation.fields
      .filter { !$0.value.isEmpty }
      .map { "\($0.label): \($0.value)" }

    return values.isEmpty ? presentation.record.id.rawValue : values.joined(separator: " · ")
  }
}

#Preview {
  List {
    BookishRecordCell(
      record: BookishRecord(
        id: BookishRecordID("book-preview"),
        kind: BookishRecordKind.book,
        properties: [
          BookishRecordKey.title: .string("The Left Hand of Darkness"),
          BookishRecordKey.authors: .list([.record(BookishRecordID("person-ursula-k-le-guin"))]),
          BookishRecordKey.status: .string("To Read"),
        ]
      ),
      layout: BookishRecord(
        id: BookishRecordID("layout-preview"),
        kind: BookishRecordKind.layout,
        properties: [
          BookishRecordKey.title: .string("Book Row"),
          BookishRecordKey.fields: .list([
            .string(BookishRecordKey.authors), .string(BookishRecordKey.status),
          ]),
        ]
      )
    )
  }
}
