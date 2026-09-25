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

  /// Resolves stored records and signals when they should be reloaded.
  @Environment(BookishStorageService.State.self) private var storage

  /// Resolves cascading presentations for the host record.
  @Environment(BookishPresentationService.State.self) private var presentationState

  /// The service used to report presentation-resolution failures.
  @Environment(BookishStatusService.State.self) private var status

  /// The navigation service used by linked record values.
  let navigation: BookishNavigationService.State

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
                RecordLinkButton(recordID: recordID)
              )
            },
            sectionView: { linkedLayoutID in
              RecordLayoutItemView(
                linkedLayoutID: linkedLayoutID,
                host: host,
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
    "\(layout.id.rawValue)-\(host.kind)-\(storage.revision)"
  }

  /// Resolves cascading field presentations for the host record in this section.
  private func loadPresentations() async {
    do {
      presentationRecords = try await presentationState.presentations(
        for: host.kind, layout: layout)
    } catch {
      status.report(error: error)
    }
  }
}
