// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import SwiftUI

/// Displays the available record indexes and changes the active browser index.
struct BrowserIndexListView: View {
  /// The datastore coordinator used to select indexes.
  let harness: BookishHarness

  /// The route containing the current index selection.
  let navigation: BookishNavigationService

  /// The list of selectable browser indexes.
  var body: some View {
    List(selection: selectedRecordIndexID) {
      Section {
        Label("Coming Soon", systemImage: "sparkles")
          .foregroundStyle(.secondary)
          .accessibilityHint("Top-level browser areas will appear here.")
      }

      Section("Library") {
        ForEach(libraryIndexes) { recordIndex in
          BrowserIndexRow(recordIndex: recordIndex)
        }
      }

      if !debugIndexes.isEmpty {
        Section("Debug") {
          ForEach(debugIndexes) { recordIndex in
            BrowserIndexRow(recordIndex: recordIndex)
          }
        }
      }
    }
    .navigationTitle("Records")
  }

  /// The non-debug indexes presented as the user-facing library.
  private var libraryIndexes: [BookishRecordIndex] {
    navigation.recordIndexes.filter { !$0.isDebugOnly }
  }

  /// The debug and configuration indexes shown only when they are available.
  private var debugIndexes: [BookishRecordIndex] {
    navigation.recordIndexes.filter(\.isDebugOnly)
  }

  /// Binds list selection to the navigation route.
  private var selectedRecordIndexID: Binding<BookishRecordID?> {
    Binding {
      navigation.selectedRecordIndexID
    } set: { recordIndexID in
      select(recordIndexID: recordIndexID)
    }
  }

  /// Selects an index without blocking SwiftUI's selection update.
  private func select(recordIndexID: BookishRecordID?) {
    Task {
      await harness.select(recordIndexID: recordIndexID)
    }
  }
}
