// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import BookishRecordView
import SwiftUI

/// Resolves and displays one record in the browser detail stack.
struct BookishRecordIDDetail: View {
  /// The identifier of the record to display.
  let recordID: BookishRecordID

  /// The datastore coordinator used to resolve record presentation.
  let harness: BookishUIStateService

  /// The service used to report record-detail failures.
  @Environment(BookishStatusService.self) private var statusService

  /// The current browser navigation route.
  let navigation: BookishNavigationService

  /// The resolved record, when it is available.
  @State private var record: BookishRecord?

  /// The layout used to display the record.
  @State private var layout: BookishRecord?

  /// The cascading property presentations for the record's kind.
  @State private var presentationRecords: [BookishRecord] = []

  /// The record detail content or its loading placeholder.
  var body: some View {
    Group {
      if let record {
        BookishRecordView(
          record: record,
          layout: layout,
          presentationResolver: CascadingPresentationResolver(
            layout: layout,
            presentationRecords: presentationRecords
          ),
          viewerRegistry: BookishValueViewerRegistry { recordID in
            AnyView(
              RecordLinkButton(
                recordID: recordID,
                harness: harness
              )
            )
          },
          sectionView: { linkedLayoutID in
            RecordLayoutItemView(
              linkedLayoutID: linkedLayoutID,
              host: record,
              harness: harness,
              navigation: navigation
            )
          }
        )
      } else {
        ContentUnavailableView(
          "Loading",
          systemImage: "book",
          description: Text(recordID.rawValue)
        )
      }
    }
    .task(id: taskID) {
      await load()
    }
  }

  /// Identifies presentation inputs that require the record to be resolved again.
  private var taskID: String {
    "\(recordID.rawValue)-\(navigation.selectedRecordIndexID?.rawValue ?? "")-\(harness.presentation.selectedLayoutID?.rawValue ?? "")-\(harness.revision)"
  }

  /// Resolves the record, selected layout, and cascading presentations.
  private func load() async {
    do {
      record = try await harness.navigation.storageService.record(id: recordID)
      if let record {
        layout = try await harness.presentation.layout(
          for: record, recordIndex: navigation.selectedRecordIndex)
        presentationRecords = try await harness.presentation.presentations(
          for: record.kind,
          layout: layout
        )
      }
    } catch {
      statusService.report(error: error)
    }
  }
}
