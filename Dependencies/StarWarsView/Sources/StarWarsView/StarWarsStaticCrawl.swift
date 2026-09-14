// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Presents crawl text without animation when the user has reduced motion enabled.
struct StarWarsStaticCrawl: View {
  /// The text to display.
  let text: String

  /// Renders the complete text in an ordinary, scrollable reading layout.
  var body: some View {
    ScrollView {
      StarWarsCrawlText(text: text, maximumWidth: 460)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
  }
}
