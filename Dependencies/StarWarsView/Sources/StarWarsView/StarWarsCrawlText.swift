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

  /// The typography used for the crawl text.
  let layout: StarWarsCrawlLayout

  /// Spacing between crawl lines that scales with the selected text size.
  @ScaledMetric(relativeTo: .title) private var lineSpacing: CGFloat = 10

  /// Renders an accessible crawl column using the selected typography.
  var body: some View {
    Group {
      switch layout {
      case .loose:
        Text(text)
          .font(.title.weight(.bold))
          .foregroundStyle(.yellow)
          .multilineTextAlignment(.center)
          .lineSpacing(lineSpacing)
          .padding(.horizontal, 24)
      case .denseJustified:
        StarWarsJustifiedText(text: text, width: maximumWidth)
      }
    }
    .frame(width: maximumWidth)
    .fixedSize(horizontal: false, vertical: true)
  }
}
