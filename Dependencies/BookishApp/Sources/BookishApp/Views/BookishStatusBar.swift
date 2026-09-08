// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Displays the current Bookish status and import progress.
struct BookishStatusBar: View {
  /// The status service that supplies the displayed message and progress.
  let statusService: BookishStatusService

  /// The navigation service that supplies the displayed record count.
  let navigation: BookishNavigationService

  /// The status bar content.
  var body: some View {
    HStack {
      if let progress = statusService.importProgress {
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
        Text(statusService.message)
      }
      Spacer()
      Text("\(navigation.recordIDs.count) records")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding()
    .frame(maxWidth: .infinity)
    .background(.bar)
  }
}
