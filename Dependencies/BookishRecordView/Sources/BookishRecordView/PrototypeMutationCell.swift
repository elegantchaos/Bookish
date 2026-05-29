import BookishDatastore
import SwiftUI

/// A compact row view for displaying a mutation in the prototype browser.
public struct PrototypeMutationCell: View {
  private let presentation: PrototypeMutationPresentation

  /// Creates a row view from a mutation record.
  public init(mutation: MutationRecord) {
    self.presentation = PrototypeMutationPresentation(mutation: mutation)
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
    PrototypeMutationCell(
      mutation: MutationRecord(
        operation: .setProperty(
          recordID: RecordID("book-preview"),
          kind: "book",
          key: "status",
          value: .string("Reading")
        )
      )
    )
  }
}
