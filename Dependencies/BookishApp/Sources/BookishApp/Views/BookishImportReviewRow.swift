import BookishImporter
import BookishRecord
import SwiftUI

/// A proposed record with a compact menu for its match decision.
struct BookishImportReviewRow: View {
  @Environment(BookishImportingService.State.self) private var importing

  let entry: BookishImportPlanEntry
  let existingByID: [BookishRecordID: BookishRecord]

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(entry.record.string(BookishRecordKey.name) ?? entry.id.rawValue)
          .font(.headline)
        Text(entry.record.kind).foregroundStyle(.secondary)
      }
      Spacer()
      if case .review(let candidates, let sameID) = entry.match {
        Menu {
          if sameID {
            Button("Use Existing") { choose(.keepExisting) }
            Button("Use Imported") { choose(.replaceExisting) }
          } else {
            ForEach(candidates, id: \.self) { candidate in
              Button("Use Existing: \(name(for: candidate))") {
                choose(.useExisting(candidate))
              }
            }
            Divider()
            Button("Add as New") { choose(.create) }
          }
        } label: {
          Label(selectedChoiceLabel, systemImage: "chevron.up.chevron.down")
            .lineLimit(1)
        }
        .controlSize(.small)
        .accessibilityLabel(
          "Import choice for \(entry.record.string(BookishRecordKey.name) ?? entry.id.rawValue)")
      }
    }
  }

  private var selectedChoiceLabel: String {
    switch importing.importChoices[entry.id] {
    case .keepExisting: "Use Existing"
    case .useExisting(let id): "Use Existing: \(name(for: id))"
    case .replaceExisting: "Use Imported"
    case .create: "Add as New"
    case nil: "Choose"
    }
  }

  private func name(for id: BookishRecordID) -> String {
    existingByID[id]?.string(BookishRecordKey.name) ?? id.rawValue
  }

  private func choose(_ choice: BookishImportChoice) {
    importing.setImportChoice(choice, for: entry.id)
  }
}
