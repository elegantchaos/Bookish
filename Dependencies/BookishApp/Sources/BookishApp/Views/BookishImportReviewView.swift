import BookishImporter
import BookishRecord
import SwiftUI

/// Reviews possible matches before an import changes the catalogue.
struct BookishImportReviewView: View {
  @Environment(BookishUIStateService.self) private var uiState
  @State private var choices: [BookishRecordID: BookishImportChoice] = [:]

  let plan: BookishImportPlan

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Review Import").font(.title2)
      Text(
        "\(plan.newCount) new · \(plan.skippedCount) already imported · \(plan.reviewEntries.count) to review"
      )
      .foregroundStyle(.secondary)

      if plan.reviewEntries.isEmpty {
        Text("No possible matches need a decision.")
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            ForEach(plan.reviewEntries) { entry in
              reviewRow(entry)
              Divider()
            }
          }
        }
      }

      HStack {
        Button("Cancel") { uiState.cancelPendingImport() }
        Spacer()
        Button("Import") {
          Task { await uiState.applyPendingImport(choices: choices) }
        }
        .disabled(choices.count != plan.reviewEntries.count)
        .buttonStyle(.borderedProminent)
      }
    }
    .padding()
    .frame(minWidth: 480, minHeight: 240)
  }

  @ViewBuilder
  private func reviewRow(_ entry: BookishImportPlanEntry) -> some View {
    if case .review(let candidates, let sameID) = entry.match {
      VStack(alignment: .leading, spacing: 8) {
        Text(entry.record.string(BookishRecordKey.name) ?? entry.id.rawValue)
          .font(.headline)
        Text(entry.record.kind).foregroundStyle(.secondary)
        if sameID {
          choiceButton("Keep catalogue version", for: entry.id, choice: .keepExisting)
          choiceButton("Use imported version", for: entry.id, choice: .replaceExisting)
        } else {
          choiceButton("Add as another record", for: entry.id, choice: .create)
          ForEach(candidates, id: \.self) { candidate in
            let existing = plan.existingSnapshot.first { $0.id == candidate }
            choiceButton(
              "Use existing: \(existing?.string(BookishRecordKey.name) ?? candidate.rawValue)",
              for: entry.id, choice: .useExisting(candidate))
          }
        }
      }
    }
  }

  private func choiceButton(
    _ title: String, for id: BookishRecordID, choice: BookishImportChoice
  ) -> some View {
    Button {
      choices[id] = choice
    } label: {
      Label(title, systemImage: choices[id] == choice ? "largecircle.fill.circle" : "circle")
    }
    .buttonStyle(.plain)
  }
}
