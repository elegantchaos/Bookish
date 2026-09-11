// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Displays the current Bookish status and import progress.
struct BookishStatusBar: View {
  @Environment(BookishEngine.self) var commander
  
  /// The status service that supplies the displayed message and progress.
  var statusService: BookishStatusService { commander.status }

  /// The navigation service that supplies the displayed record count.
  var navigation: BookishNavigationService { commander.navigation }

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
