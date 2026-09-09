// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import SwiftUI

/// Displays the available record indexes and changes the active browser index.
struct BrowserIndexListView: View {
  /// The route containing the current index selection.
  let navigation: BookishNavigationService

  /// The command boundary used to report navigation failures.
  @Environment(\.bookishCommandCentre) private var commander

  /// The list of selectable browser indexes.
  var body: some View {
    List(selection: selectedDestination) {
      Section("Workflows") {
        ForEach(BookishMainSection.allCases, id: \.self) { section in
          Label(section.title, systemImage: section.systemImage)
            .tag(BrowserDestination.mainSection(section))
        }
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

  /// Identifies a selectable row in the browser sidebar.
  enum BrowserDestination: Hashable {
    /// A top-level workflow.
    case mainSection(BookishMainSection)

    /// A record browser index.
    case recordIndex(BookishRecordID)
  }

  /// The non-debug indexes presented as the user-facing library.
  private var libraryIndexes: [BookishRecordIndex] {
    navigation.recordIndexes.filter { !$0.isDebugOnly }
  }

  /// The debug and configuration indexes shown only when they are available.
  private var debugIndexes: [BookishRecordIndex] {
    navigation.recordIndexes.filter(\.isDebugOnly)
  }

  /// Binds list selection to the active sidebar route.
  private var selectedDestination: Binding<BrowserDestination?> {
    Binding {
      if let section = navigation.selectedMainSection {
        return .mainSection(section)
      }

      return navigation.selectedRecordIndexID.map(BrowserDestination.recordIndex)
    } set: { destination in
      select(destination: destination)
    }
  }

  /// Updates the visible area without blocking SwiftUI's selection update.
  private func select(destination: BrowserDestination?) {
    guard let destination else {
      return
    }

    switch destination {
    case .mainSection(let section):
      navigation.select(mainSection: section)

    case .recordIndex(let recordIndexID):
      select(recordIndexID: recordIndexID)
    }
  }

  /// Selects an index asynchronously.
  private func select(recordIndexID: BookishRecordID) {
    Task {
      do {
        try await navigation.select(recordIndexID: recordIndexID)
      } catch {
        commander?.statusService.report(error: error)
      }
    }
  }
}
