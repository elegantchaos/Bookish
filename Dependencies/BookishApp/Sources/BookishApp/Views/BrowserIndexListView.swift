// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import SwiftUI

/// Displays the available record indexes and changes the active browser index.
struct BrowserIndexListView: View {
  /// The command boundary used to report navigation failures.
  @Environment(BookishCommander.self) private var commander

  /// The navigation state displayed by the sidebar.
  @Environment(BookishNavigationService.self) private var navigation

  /// The list of selectable browser indexes.
  var body: some View {
    ScrollViewReader { scrollProxy in
      List(selection: selectedDestination) {
        Section("Workflows") {
          ForEach(BookishMainSection.allCases, id: \.self) { section in
            Label(section.title, systemImage: section.systemImage)
              .tag(BrowserDestination.mainSection(section))
          }
        }

        Section("Library") {
          ForEach(navigation.libraryIndexes) { recordIndex in
            BrowserIndexRow(recordIndex: recordIndex)
              .id(BrowserDestination.recordIndex(recordIndex.id))
          }
        }

        if !navigation.debugIndexes.isEmpty {
          Section("Debug") {
            ForEach(navigation.debugIndexes) { recordIndex in
              BrowserIndexRow(recordIndex: recordIndex)
                .id(BrowserDestination.recordIndex(recordIndex.id))
            }
          }
        }
      }
      .navigationTitle("Records")
      .onChange(of: selectedIndexDestination, initial: true) { _, destination in
        guard let destination else { return }
        scrollProxy.scrollTo(destination)
      }
    }
  }

  /// Identifies a selectable row in the browser sidebar.
  enum BrowserDestination: Hashable {
    /// A top-level workflow.
    case mainSection(BookishMainSection)

    /// A record browser index.
    case recordIndex(BookishRecordID)
  }

  /// The selected index row once it is available in the sidebar.
  private var selectedIndexDestination: BrowserDestination? {
    guard navigation.selectedMainSection == nil,
      let id = navigation.selectedRecordIndexID,
      navigation.recordIndexIDs.contains(id)
    else { return nil }

    return .recordIndex(id)
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
      commander.perform(SelectMainSectionCommand(section: section))

    case .recordIndex(let recordIndexID):
      commander.perform(SelectRecordIndexCommand(recordIndexID: recordIndexID))
    }
  }
}
