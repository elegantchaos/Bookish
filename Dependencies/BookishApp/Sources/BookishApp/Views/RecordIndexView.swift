// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import BookishRecord
import BookishRecordView

struct RecordIndexView: View {
  let harness: BookishHarness
  let navigation: BookishNavigationService

  @State private var layout: BookishRecord?
  @State private var presentationsByKind: [String: [BookishRecord]] = [:]
  @State private var metadataByKind: [String: BookishRecord] = [:]

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

  private var selectedRecordID: Binding<BookishRecordID?> {
    Binding {
      navigation.selectedRecordID
    } set: { recordID in
      navigation.select(recordID: recordID)
    }
  }

  private var taskID: String {
    "\(navigation.selectedRecordIndexID?.rawValue ?? "")-\(harness.selectedLayoutID?.rawValue ?? "")-\(harness.revision)"
  }

  private func loadPresentation() async {
    do {
      layout = try await harness.selectedLayout()
      var presentationsByKind: [String: [BookishRecord]] = [:]
      for kind in Set(navigation.selectedRecordResult?.records.map(\.kind) ?? []) {
        presentationsByKind[kind] = try await harness.presentations(for: kind, layout: layout)
        if let metadata = try await harness.recordKindMetadata(for: kind) {
          metadataByKind[kind] = metadata
        }
      }
      self.presentationsByKind = presentationsByKind
    } catch {
      harness.report(error: error)
    }
  }
}
