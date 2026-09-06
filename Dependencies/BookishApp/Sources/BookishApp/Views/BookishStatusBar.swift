// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Displays the current datastore status and import progress.
struct BookishStatusBar: View {
  /// The datastore coordinator that supplies the displayed status.
  let harness: BookishHarness

  /// The status bar content.
  var body: some View {
    HStack {
      if let progress = harness.importProgress {
        if let total = progress.total {
          ProgressView(
            progress.message,
            value: Double(progress.completed),
            total: Double(total)
          )
        } else {
          ProgressView(progress.message)
        }
      } else {
        Text(harness.status)
      }
      Spacer()
      Text("\(harness.navigation.recordIDs.count) records")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding()
    .frame(maxWidth: .infinity)
    .background(.bar)
  }
}
