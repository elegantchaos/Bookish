import BookishImporter
import BookishRecord
import SwiftUI

/// Reviews possible matches inside the Import workflow.
struct BookishImportReviewView: View {
  @Environment(BookishCommander.self) private var commander
  @Environment(BookishImportingService.State.self) private var importing

  #if os(macOS)
    @State private var selectedIDs: Set<BookishRecordID> = []
  #endif

  let plan: BookishImportPlan
  private let existingByID: [BookishRecordID: BookishRecord]

  init(plan: BookishImportPlan) {
    self.plan = plan
    existingByID = Dictionary(
      uniqueKeysWithValues: plan.existingSnapshot.map { ($0.id, $0) })
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("Review Import").font(.title2)
      Text(
        "\(plan.newCount) new · \(plan.skippedCount) already imported · \(plan.reviewEntries.count) possible matches"
      )
      .foregroundStyle(.secondary)

      if plan.reviewEntries.isEmpty {
        ContentUnavailableView(
          "No Matches to Review", systemImage: "checkmark.circle",
          description: Text("The proposed import is ready."))
      } else {
        #if os(macOS)
          HStack {
            Text("Select rows with Command or Shift to change several at once.")
              .foregroundStyle(.secondary)
            Spacer()
            Menu("Set Selected To") {
              Button("Use Existing") { setSelectedChoices(.existing) }
              Button("Use Imported") { setSelectedChoices(.imported) }
            }
            .disabled(selectedIDs.isEmpty)
          }
          List(selection: $selectedIDs) {
            reviewRows
          }
        #else
          List {
            reviewRows
          }
        #endif
      }

      HStack {
        commander.button(CancelPendingImportCommand())
        Spacer()
        commander.button(ApplyPendingImportCommand())
          .buttonStyle(.borderedProminent)
      }
    }
    .padding()
  }

  private var reviewRows: some View {
    ForEach(plan.reviewEntries) { entry in
      BookishImportReviewRow(entry: entry, existingByID: existingByID)
        .tag(entry.id)
    }
  }

  #if os(macOS)
    private func setSelectedChoices(_ preference: BookishImportPreference) {
      importing.setImportChoices(for: selectedIDs, preferring: preference)
    }
  #endif
}
