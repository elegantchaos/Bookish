import BookishImporter
import BookishRecord
import SwiftUI

/// A proposed record with a popup for how the import should handle it.
struct BookishImportReviewRow: View {
  @Environment(BookishImportingService.State.self) private var importing

  let entry: BookishImportPlanEntry
  let existingByID: [BookishRecordID: BookishRecord]

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(entry.displayName)
          .font(.headline)
        Text(entry.record.kind).foregroundStyle(.secondary)
      }
      Spacer()
      Picker("Import Choice", selection: choice) {
        ForEach(entry.availableChoices, id: \.self) { choice in
          Text(label(for: choice)).tag(Optional(choice))
        }
      }
      .pickerStyle(.menu)
      .labelsHidden()
      .fixedSize()
      .accessibilityLabel("Import choice for \(entry.displayName)")
    }
  }

  private var choice: Binding<BookishImportChoice?> {
    Binding(
      get: { importing.importChoices[entry.id] },
      set: { choice in
        if let choice { importing.setImportChoice(choice, for: [entry.id]) }
      })
  }

  private func label(for choice: BookishImportChoice) -> String {
    switch choice {
    case .create: entry.match == .create ? "Add" : "Add as New"
    case .skip: "Skip"
    case .keepExisting: "Keep Existing"
    case .replaceExisting: "Replace Existing"
    case .useExisting(let id): "Use Existing: \(name(for: id))"
    }
  }

  private func name(for id: BookishRecordID) -> String {
    existingByID[id]?.string(BookishRecordKey.name) ?? id.rawValue
  }
}
