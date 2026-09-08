// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import BookishRecordView
import SwiftUI

/// Resolves and renders one record as a reusable browser cell.
struct BookishRecordIDCell: View {
  /// The identifier of the record to render.
  let recordID: BookishRecordID

  /// The datastore coordinator used to resolve the record.
  let harness: BookishHarness

  /// The command boundary used to report record-resolution failures.
  @Environment(\.bookishCommandCentre) private var commander

  /// The resolved record, when available.
  @State private var record: BookishRecord?

  /// The layout used to render the cell.
  @State private var layout: BookishRecord?

  /// The cascading property presentations for the record's kind.
  @State private var presentationRecords: [BookishRecord] = []

  /// The resolved record cell or its identifier fallback.
  var body: some View {
    Group {
      if let record {
        BookishRecordCell(
          record: record,
          layout: layout,
          presentationResolver: CascadingPresentationResolver(
            layout: layout,
            presentationRecords: presentationRecords))
      } else {
        Text(recordID.rawValue)
      }
    }
    .task(id: taskID) {
      await load()
    }
  }

  /// Identifies inputs that require the cell to resolve its record again.
  private var taskID: String {
    "\(recordID.rawValue)-\(harness.presentation.selectedLayoutID?.rawValue ?? "")-\(harness.revision)"
  }

  /// Resolves the record, selected layout, and cascading presentations.
  private func load() async {
    do {
      record = try await harness.storageService.record(id: recordID)
      layout = try await harness.presentation.selectedLayout(
        for: harness.navigation.selectedRecordIndex)
      if let record {
        presentationRecords = try await harness.presentation.presentations(
          for: record.kind, layout: layout)
      }
    } catch {
      commander?.statusService.report(error: error)
    }
  }
}
