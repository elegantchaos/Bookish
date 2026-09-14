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

  /// The typography used for the crawl text.
  let layout: StarWarsCrawlLayout

  /// The camera projection used to present the text plane.
  let camera: StarWarsCrawlCamera

  /// The untransformed height of the crawl text.
  @State private var contentHeight: CGFloat = 0

  /// Creates a crawl scene with the supplied text, phase, layout, and camera.
  init(
    text: String,
    progress: CGFloat,
    layout: StarWarsCrawlLayout,
    camera: StarWarsCrawlCamera = .standard
  ) {
    self.text = text
    self.progress = progress
    self.layout = layout
    self.camera = camera
  }

  /// Measures the text and maps its current phase to the viewport.
  var body: some View {
    GeometryReader { proxy in
      let motion = CrawlMotion(
        elapsed: TimeInterval(progress),
        duration: 1,
        viewportHeight: proxy.size.height,
        contentHeight: contentHeight
      )

      StarWarsCrawlText(
        text: text,
        maximumWidth: textWidth(for: proxy.size.width),
        layout: layout
      )
      .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
        contentHeight = height
      }
      .frame(maxWidth: .infinity, alignment: .top)
      .offset(y: motion.verticalOffset)
      .opacity(motion.progress == 0 ? 0 : 1)
      .rotation3DEffect(
        .degrees(camera.tiltDegrees),
        axis: (x: 1, y: 0, z: 0),
        anchor: .top,
        perspective: camera.perspective
      )
    }
    .clipped()
  }

  /// Limits the crawl column while retaining usable margins on compact screens.
  private func textWidth(for viewportWidth: CGFloat) -> CGFloat {
    min(max(viewportWidth - 48, 160), camera.maximumTextWidth)
  }
}
