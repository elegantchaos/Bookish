import BookishDatastore
import BookishRecord
import SwiftUI

/// Displays a prototype mutation record.
public struct PrototypeMutationView: View {
  private let presentation: PrototypeMutationPresentation

  /// Creates a mutation detail view.
  public init(mutation: MutationRecord) {
    self.presentation = PrototypeMutationPresentation(mutation: mutation)
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
  PrototypeMutationView(
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
