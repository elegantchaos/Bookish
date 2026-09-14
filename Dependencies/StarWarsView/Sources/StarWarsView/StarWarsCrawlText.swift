// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Styles the text shared by the animated crawl and its Reduce Motion fallback.
struct StarWarsCrawlText: View {
  /// The text to display.
  let text: String

  /// The widest readable crawl column.
  let maximumWidth: CGFloat

  /// Spacing between crawl lines that scales with the selected text size.
  @ScaledMetric(relativeTo: .title) private var lineSpacing: CGFloat = 10

  /// Renders an accessible, centered column of crawl text.
  var body: some View {
    Text(text)
      .font(.title.weight(.bold))
      .foregroundStyle(.yellow)
      .multilineTextAlignment(.center)
      .lineSpacing(lineSpacing)
      .frame(maxWidth: maximumWidth)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.horizontal, 24)
  }
}
