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

  /// Resolves stored records and signals when they should be reloaded.
  @Environment(BookishStorageService.State.self) private var storage

  /// Resolves layouts, presentations, and record-kind metadata.
  @Environment(BookishPresentationService.State.self) private var presentation

  /// The command boundary for actions on this visible record.
  @Environment(BookishCommander.self) private var commander

  /// Reports record and presentation loading failures.
  @Environment(BookishStatusService.State.self) private var status

  #if os(iOS)
    /// The current width class used to avoid a duplicate record title on compact screens.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif

  /// The current browser navigation route.
  let navigation: BookishNavigationService.State

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
              RecordLinkButton(recordID: recordID)
            )
          },
          showsNavigationTitle: showsNavigationTitle,
          sectionView: { linkedLayoutID in
            RecordLayoutItemView(
              linkedLayoutID: linkedLayoutID,
              host: record,
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
    .toolbar {
      if record?.kind == BookishRecordKind.book {
        commander.toolbarItem(MarkReadingCommand(recordID: recordID))
        commander.toolbarItem(MarkFinishedCommand(recordID: recordID))
      }
    }
  }

  /// Keeps the platform navigation title where it has room to add context.
  private var showsNavigationTitle: Bool {
    #if os(iOS)
      horizontalSizeClass != .compact
    #else
      true
    #endif
  }

  /// Identifies presentation inputs that require the record to be resolved again.
  private var taskID: String {
    "\(recordID.rawValue)-\(navigation.selectedRecordIndexID?.rawValue ?? "")-\(presentation.selectedLayoutID?.rawValue ?? "")-\(storage.revision)"
  }

  /// Resolves the record, selected layout, and cascading presentations.
  private func load() async {
    do {
      record = try await storage.record(id: recordID)
      if let record {
        layout = try await presentation.layout(
          for: record, recordIndex: navigation.selectedRecordIndex)
        presentationRecords = try await presentation.presentations(
          for: record.kind,
          layout: layout
        )
      }
    } catch {
      status.report(error: error)
    }
  }
}
