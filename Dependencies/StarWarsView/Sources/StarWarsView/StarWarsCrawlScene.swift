// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Renders a single, independently controllable visual state of the crawl.
struct StarWarsCrawlScene: View {
  /// The text to present.
  let text: String

  /// The normalized crawl position.
  let progress: CGFloat

  /// The untransformed height of the crawl text.
  @State private var contentHeight: CGFloat = 0

  /// Measures the text and maps its current phase to the viewport.
  var body: some View {
    GeometryReader { proxy in
      let motion = CrawlMotion(
        elapsed: TimeInterval(progress),
        duration: 1,
        viewportHeight: proxy.size.height,
        contentHeight: contentHeight
      )

      StarWarsCrawlText(text: text, maximumWidth: textWidth(for: proxy.size.width))
        .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
          contentHeight = height
        }
        .scaleEffect(motion.scale, anchor: .top)
        .rotation3DEffect(
          .degrees(55),
          axis: (x: 1, y: 0, z: 0),
          anchor: .top,
          perspective: 0.8
        )
        .offset(y: motion.verticalOffset)
    }
    .clipped()
  }

  /// Limits the crawl column while retaining usable margins on compact screens.
  private func textWidth(for viewportWidth: CGFloat) -> CGFloat {
    min(max(viewportWidth - 48, 160), 460)
  }
}
