import BookishImporter
import BookishRecord
import SwiftUI

/// Lists every record a pending import would add, each with a choice of how to handle it.
struct BookishImportReviewView: View {
  @Environment(BookishCommander.self) private var commander
  @Environment(BookishImportingService.State.self) private var importing

  @State private var selectedIDs: Set<BookishRecordID> = []

  let plan: BookishImportPlan
  private let existingByID: [BookishRecordID: BookishRecord]
  private let entriesByID: [BookishRecordID: BookishImportPlanEntry]
  private let newEntries: [BookishImportPlanEntry]

  init(plan: BookishImportPlan) {
    self.plan = plan
    existingByID = Dictionary(
      uniqueKeysWithValues: plan.existingSnapshot.map { ($0.id, $0) })
    entriesByID = Dictionary(uniqueKeysWithValues: plan.entries.map { ($0.id, $0) })
    newEntries = plan.newEntries.sorted {
      ($0.record.kind, $0.displayName) < ($1.record.kind, $1.displayName)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
        .padding()

      if plan.reviewEntries.isEmpty && newEntries.isEmpty {
        ContentUnavailableView(
          "Nothing New to Import", systemImage: "checkmark.circle",
          description: Text("Every record in this source is already in your catalogue.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(selection: $selectedIDs) {
          sections
        }
        .contextMenu(forSelectionType: BookishRecordID.self) { ids in
          BookishImportChoiceMenu(ids: ids, entriesByID: entriesByID)
        }
      }

      Divider()
      actions
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .toolbar {
      #if os(iOS)
        ToolbarItem {
          EditButton()
        }
      #endif
      ToolbarItem {
        Menu {
          BookishImportChoiceMenu(ids: selectedIDs, entriesByID: entriesByID)
        } label: {
          Label("Set Selected To", systemImage: "checklist")
        }
        .disabled(selectedIDs.isEmpty)
        .help("Change how the selected records are imported.")
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading) {
      Text("Review Import").font(.title2)
      Text(summary)
        .foregroundStyle(.secondary)
    }
  }

  private var summary: String {
    "\(plan.newCount) new · \(plan.reviewEntries.count) possible matches · \(plan.skippedCount) already imported"
  }

  private var actions: some View {
    HStack {
      commander.button(CancelPendingImportCommand())
        .buttonStyle(.bordered)
      Spacer()
      commander.button(ApplyPendingImportCommand())
        .buttonStyle(.borderedProminent)
    }
    .controlSize(.large)
  }

  @ViewBuilder private var sections: some View {
    if !plan.reviewEntries.isEmpty {
      Section("Possible Matches") {
        ForEach(plan.reviewEntries) { entry in
          BookishImportReviewRow(entry: entry, existingByID: existingByID)
            .tag(entry.id)
        }
      }
    }

    if !newEntries.isEmpty {
      Section {
        ForEach(newEntries) { entry in
          BookishImportReviewRow(entry: entry, existingByID: existingByID)
            .tag(entry.id)
        }
      } header: {
        HStack {
          Text("New Records")
          Spacer()
          Button("Add All") { importing.setImportChoice(.create, for: allNewIDs) }
          Button("Skip All") { importing.setImportChoice(.skip, for: allNewIDs) }
        }
        .buttonStyle(.borderless)
      }
    }
  }

  private var allNewIDs: Set<BookishRecordID> { Set(newEntries.map(\.id)) }
}

/// Bulk import choices for a set of records, offering only those that fit at least one of them.
struct BookishImportChoiceMenu: View {
  @Environment(BookishImportingService.State.self) private var importing

  let ids: Set<BookishRecordID>
  let entriesByID: [BookishRecordID: BookishImportPlanEntry]

  var body: some View {
    let entries = ids.compactMap { entriesByID[$0] }
    let allowsAdd = entries.contains { $0.availableChoices.contains(.create) }
    let allowsSkip = entries.contains { $0.availableChoices.contains(.skip) }
    let hasMatches = entries.contains {
      if case .review = $0.match { return true }
      return false
    }

    if allowsAdd {
      Button("Add") { importing.setImportChoice(.create, for: ids) }
    }
    if allowsSkip {
      Button("Skip") { importing.setImportChoice(.skip, for: ids) }
    }
    if hasMatches {
      Divider()
      Button("Use Existing") { importing.setImportChoices(for: ids, preferring: .existing) }
      Button("Use Imported") { importing.setImportChoices(for: ids, preferring: .imported) }
    }
  }
}

extension BookishImportPlanEntry {
  /// The record's name, falling back to its identifier.
  var displayName: String { record.string(BookishRecordKey.name) ?? id.rawValue }
}
