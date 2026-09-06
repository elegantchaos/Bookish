// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import BookishRecordView
import SwiftUI

struct RecordDetailView: View {
  let harness: BookishHarness
  let navigation: BookishNavigationService

  var body: some View {
    NavigationStack(path: recordNavigationPath) {
      Group {
        if let recordID = navigation.selectedRecordID {
          BookishRecordIDDetail(recordID: recordID, harness: harness, navigation: navigation)
        } else {
          ContentUnavailableView(
            "No Selection", systemImage: "list.bullet.rectangle", description: Text(harness.status))
        }
      }
      .navigationDestination(for: BookishRecordID.self) { recordID in
        BookishRecordIDDetail(recordID: recordID, harness: harness, navigation: navigation)
      }
    }
  }

  private var recordNavigationPath: Binding<[BookishRecordID]> {
    Binding {
      navigation.recordNavigationPath
    } set: { path in
      navigation.setRecordNavigationPath(path)
    }
  }
}
