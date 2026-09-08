// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import BookishRecordView
import SwiftUI

/// Displays records returned by the currently selected browser index.
struct RecordIndexView: View {
  /// The datastore coordinator that resolves layouts and metadata.
  let harness: BookishHarness

  /// The command boundary used to report record-index failures.
  @Environment(\.bookishCommandCentre) private var commander

  /// The route containing the active index and record selection.
  let navigation: BookishNavigationService

  /// The layout currently used to render index rows.
  @State private var layout: BookishRecord?

  /// Resolved presentation records keyed by catalogue kind.
  @State private var presentationsByKind: [String: [BookishRecord]] = [:]

  /// Metadata records keyed by catalogue kind.
  @State private var metadataByKind: [String: BookishRecord] = [:]

  /// The list of records selected by the active index.
  var body: some View {
    List(selection: selectedRecordID) {
      ForEach(navigation.selectedRecordResult?.records ?? []) { record in
        BookishRecordIndexCell(
          record: record,
          layout: layout,
          placeholderSystemImage: metadataByKind[record.kind]?.string(BookishRecordKey.icon)
            ?? "doc",
          presentationResolver: CascadingPresentationResolver(
            layout: layout,
            presentationRecords: presentationsByKind[record.kind] ?? [])
        )
        .tag(Optional(record.id))
      }
    }
    .navigationTitle(navigation.selectedRecordIndexName ?? "Index")
    .task(id: taskID) {
      await loadPresentation()
    }
  }

  /// Binds list selection to the selected record identifier.
  private var selectedRecordID: Binding<BookishRecordID?> {
    Binding {
      navigation.selectedRecordID
    } set: { recordID in
      navigation.select(recordID: recordID)
    }
  }

  /// Identifies data changes that require row presentations to be resolved again.
  private var taskID: String {
    "\(navigation.selectedRecordIndexID?.rawValue ?? "")-\(harness.presentation.selectedLayoutID?.rawValue ?? "")-\(harness.revision)"
  }

  /// Resolves the active layout and the metadata needed by visible record kinds.
  private func loadPresentation() async {
    do {
      layout = try await harness.presentation.selectedLayout(for: navigation.selectedRecordIndex)
      var presentationsByKind: [String: [BookishRecord]] = [:]
      for kind in Set(navigation.selectedRecordResult?.records.map(\.kind) ?? []) {
        presentationsByKind[kind] = try await harness.presentation.presentations(
          for: kind, layout: layout)
        if let metadata = try await harness.presentation.recordKindMetadata(for: kind) {
          metadataByKind[kind] = metadata
        }
      }
      self.presentationsByKind = presentationsByKind
    } catch {
      commander?.statusService.report(error: error)
    }
  }
}
