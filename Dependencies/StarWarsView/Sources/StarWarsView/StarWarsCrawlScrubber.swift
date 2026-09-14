// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Provides an interactive preview of every point in the crawl animation.
private struct StarWarsCrawlScrubber: View {
  /// The text to preview.
  let text: String

  /// The manually selected normalized crawl position.
  @State private var progress = 0.0

  /// Renders the crawl above a phase slider.
  var body: some View {
    VStack(spacing: 16) {
      StarWarsCrawlScene(text: text, progress: CGFloat(progress))
        .frame(minHeight: 360)

      VStack(alignment: .leading) {
        Text("Crawl Progress")

        Slider(value: $progress, in: 0...1)

        Text(progress, format: .number.precision(.fractionLength(1)))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal)
    }
    .padding(.vertical)
    .background(.black)
  }
}

#Preview("Scrubbed Crawl") {
  StarWarsCrawlScrubber(text: StarWarsView.defaultText)
    .frame(width: 640, height: 560)
}
