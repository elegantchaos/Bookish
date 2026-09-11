// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import BookishRecordView
import SwiftUI

/// Displays the selected record and linked-record navigation stack.
struct RecordDetailView: View {
  @Environment(BookishEngine.self) var commander
  
  /// The datastore coordinator used by record detail views.
  var harness: BookishUIStateService { commander.uiState }

  /// The route containing the selected record and detail path.
  var navigation: BookishNavigationService { commander.navigation }

  /// The detail navigation stack for the selected record.
  var body: some View {
    NavigationStack(path: recordNavigationPath) {
      Group {
        if let recordID = navigation.selectedRecordID {
          BookishRecordIDDetail(
            recordID: recordID,
            harness: harness,
            navigation: navigation
          )
        } else {
          ContentUnavailableView(
            "No Selection", systemImage: "list.bullet.rectangle",
            description: Text(harness.statusService.message))
        }
      }
      .navigationDestination(for: BookishRecordID.self) { recordID in
        BookishRecordIDDetail(
          recordID: recordID,
          harness: harness,
          navigation: navigation
        )
      }
    }
  }

  /// Binds user-driven stack changes back to the navigation service.
  private var recordNavigationPath: Binding<[BookishRecordID]> {
    Binding {
      navigation.recordNavigationPath
    } set: { path in
      navigation.setRecordNavigationPath(path)
    }
  }
}
