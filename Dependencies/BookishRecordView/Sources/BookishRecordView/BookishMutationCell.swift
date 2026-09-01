import BookishDatastore
import BookishRecord
import SwiftUI

/// A compact row view for displaying a mutation in the Bookish browser.
public struct BookishMutationCell: View {
  private let presentation: BookishMutationPresentation

  /// Creates a row view from a mutation record.
  public init(mutation: MutationRecord) {
    self.presentation = BookishMutationPresentation(mutation: mutation)
  }

  /// The SwiftUI content for the row.
  public var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Text(presentation.title)
          .font(.headline)
        Spacer()
        Text(presentation.createdAtText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(presentation.subtitle)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }
}

#Preview {
  List {
    BookishMutationCell(
      mutation: MutationRecord(
        operation: .setProperty(
          recordID: BookishRecordID("book-preview"),
          kind: BookishRecordKind.book,
          key: BookishRecordKey.status,
          value: .string("Reading")
        )
      )
    )
  }
}
