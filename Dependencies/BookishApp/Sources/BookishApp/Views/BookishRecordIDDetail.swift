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
  let harness: BookishHarness

  /// The current browser navigation route.
  let navigation: BookishNavigationService

  /// The application-owned command boundary for linked record navigation.
  let commander: BookishCommandCentre

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
                harness: harness,
                commander: commander
              )
            )
          },
          sectionView: { linkedLayoutID in
            RecordLayoutItemView(
              linkedLayoutID: linkedLayoutID,
              host: record,
              harness: harness,
              navigation: navigation,
              commander: commander
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
    "\(recordID.rawValue)-\(navigation.selectedRecordIndexID?.rawValue ?? "")-\(harness.selectedLayoutID?.rawValue ?? "")-\(harness.revision)"
  }

  /// Resolves the record, selected layout, and cascading presentations.
  private func load() async {
    do {
      record = try await harness.record(id: recordID)
      if let record {
        layout = try await harness.layout(for: record)
        presentationRecords = try await harness.presentations(
          for: record.kind,
          layout: layout
        )
      }
    } catch {
      harness.report(error: error)
    }
  }
}
