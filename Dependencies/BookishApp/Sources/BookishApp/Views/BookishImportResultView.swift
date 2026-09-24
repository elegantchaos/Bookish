import BookishRecord
import SwiftUI

/// Shows records added by the last completed import.
struct BookishImportResultView: View {
  let result: BookishImportWorkflowResult

  var body: some View {
    VStack(alignment: .leading) {
      Text("Imported from \(result.sourceName)")
        .font(.title2)
      Text(
        "\(result.importedRecords.count) added · \(result.reusedCount) existing records reused · \(result.skippedCount) already imported"
      )
      .foregroundStyle(.secondary)

      if result.importedRecords.isEmpty {
        ContentUnavailableView(
          "No New Records", systemImage: "checkmark.circle",
          description: Text("The selected records were already in your catalogue."))
      } else {
        List(result.importedRecords) { record in
          VStack(alignment: .leading) {
            Text(record.string(BookishRecordKey.name) ?? record.id.rawValue)
            Text(record.kind).foregroundStyle(.secondary)
          }
        }
      }
    }
    .padding()
  }
}
