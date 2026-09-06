// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import BookishRecord

struct BrowserIndexListView: View {
  let harness: BookishHarness
  let navigation: BookishNavigationService

  var body: some View {
    List(selection: selectedRecordIndexID) {
      ForEach(navigation.recordIndexes) { recordIndex in
        Label(recordIndex.name, systemImage: recordIndex.icon ?? "list.bullet")
          .tag(Optional(recordIndex.id))
      }
    }
    .navigationTitle("Records")
  }

  private var selectedRecordIndexID: Binding<BookishRecordID?> {
    Binding {
      navigation.selectedRecordIndexID
    } set: { recordIndexID in
      Task {
        await harness.select(recordIndexID: recordIndexID)
      }
    }
  }
}
