import BookishDatastore
import BookishRecord
import SwiftUI

/// Displays a Bookish mutation record.
public struct BookishMutationView: View {
  private let presentation: BookishMutationPresentation

  /// Creates a mutation detail view.
  public init(mutation: MutationRecord) {
    self.presentation = BookishMutationPresentation(mutation: mutation)
  }

  /// The SwiftUI content for the mutation detail view.
  public var body: some View {
    Form {
      Section {
        LabeledContent("Mutation ID") {
          Text(presentation.mutation.id.rawValue)
            .textSelection(.enabled)
        }

        LabeledContent("Created") {
          Text(presentation.createdAtText)
            .textSelection(.enabled)
        }
      } header: {
        Text("Mutation")
      }

      Section {
        ForEach(presentation.fields) { field in
          LabeledContent(field.label) {
            Text(field.value)
              .textSelection(.enabled)
          }
        }
      } header: {
        Text("Operation")
      }
    }
    .formStyle(.grouped)
    .navigationTitle(presentation.title)
  }
}

#Preview {
  BookishMutationView(
    mutation: MutationRecord(
      operation: .setProperty(
        recordID: BookishRecordID("book-preview"),
        kind: "book",
        key: "status",
        value: .string("Reading")
      )
    )
  )
}
