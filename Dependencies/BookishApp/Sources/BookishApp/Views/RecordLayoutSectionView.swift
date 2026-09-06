// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import BookishRecordView
import SwiftUI

/// Displays a named layout section while preserving the host record's navigation behaviour.
struct RecordLayoutSectionView: View {
  /// The layout record defining this section's title and ordered fields.
  let layout: BookishRecord

  /// The record whose fields are rendered by the section.
  let host: BookishRecord

  /// The datastore coordinator used to resolve cascading presentations.
  let harness: BookishHarness

  /// The navigation service used by linked record values.
  let navigation: BookishNavigationService

  /// The ancestor layout identifiers used to prevent recursive sections.
  let layoutPath: Set<BookishRecordID>

  /// The cascading property presentations for the section's host kind.
  @State private var presentationRecords: [BookishRecord] = []

  /// The display-ready host record fields for this section's layout.
  private var presentation: BookishRecordPresentation {
    BookishRecordPresentation(
      record: host,
      layout: layout,
      presentationResolver: CascadingPresentationResolver(
        layout: layout,
        presentationRecords: presentationRecords))
  }

  /// The titled Form section and its fields.
  var body: some View {
    Group {
      if !presentation.layoutItems.isEmpty {
        Section(layout.string(BookishRecordKey.name) ?? "Details") {
          BookishRecordFieldsView(
            presentation: presentation,
            viewerRegistry: BookishValueViewerRegistry { recordID in
              AnyView(
                RecordLinkButton(recordID: recordID, harness: harness, navigation: navigation)
              )
            },
            sectionView: { linkedLayoutID in
              RecordLayoutItemView(
                linkedLayoutID: linkedLayoutID,
                host: host,
                harness: harness,
                navigation: navigation,
                layoutPath: layoutPath.union([layout.id]))
            })
        }
      }
    }
    .task(id: taskID) {
      await loadPresentations()
    }
  }

  /// Identifies presentation inputs that require the section fields to be refreshed.
  private var taskID: String {
    "\(layout.id.rawValue)-\(host.kind)-\(harness.revision)"
  }

  /// Resolves cascading field presentations for the host record in this section.
  private func loadPresentations() async {
    do {
      presentationRecords = try await harness.presentations(for: host.kind, layout: layout)
    } catch {
      harness.report(error: error)
    }
  }
}
