// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct BookishStatusBar: View {
  let harness: BookishHarness

  var body: some View {
    HStack {
      status
      Spacer()
      Text("\(harness.navigation.recordIDs.count) records")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding()
    .frame(maxWidth: .infinity)
    .background(.bar)
  }

  @ViewBuilder
  private var status: some View {
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
  }
}
