// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import SwiftUI

/// Displays one selectable record index in a browser sidebar section.
struct BrowserIndexRow: View {
  /// The index record represented by this row.
  let recordIndex: BookishRecordIndex

  /// The labelled and tagged sidebar row.
  var body: some View {
    Label(recordIndex.name, systemImage: recordIndex.icon ?? "list.bullet")
      .tag(BrowserIndexListView.BrowserDestination.recordIndex(recordIndex.id))
  }
}
