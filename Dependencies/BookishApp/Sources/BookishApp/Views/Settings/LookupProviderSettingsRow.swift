// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import SwiftUI

/// Displays one lookup provider's availability and description in settings.
struct LookupProviderSettingsRow: View {
  /// The provider whose configuration state the row represents.
  let provider: any BookLookupProvider

  /// The row content.
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(provider.label)
        Spacer()
        Text(provider.isSupported ? "Available" : "API Key Required")
          .foregroundStyle(.secondary)
      }

      Text(provider.description)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
