// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Animates crawl text from below the viewport until it has receded beyond it.
struct StarWarsAnimatedCrawl: View {
  /// The text to animate.
  let text: String

  /// The duration of a single crawl.
  let duration: TimeInterval

  /// The time at which the current crawl began.
  @State private var startDate: Date?

  /// Whether the current crawl has completed.
  @State private var hasFinished = false

  /// Renders the crawl while it is active, then removes it from the viewport.
  var body: some View {
    Group {
      if hasFinished {
        Color.clear
      } else {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
          let progress = progress(at: timeline.date)

          StarWarsCrawlScene(text: text, progress: progress)
            .onChange(of: progress == 1) { _, isComplete in
              if isComplete {
                hasFinished = true
              }
            }
        }
      }
    }
    .onAppear(perform: start)
  }

  /// Begins a new crawl whenever this view enters the hierarchy.
  private func start() {
    startDate = .now
    hasFinished = false
  }

  /// Returns a normalized crawl position for the supplied timeline date.
  private func progress(at date: Date) -> CGFloat {
    CrawlMotion.progress(elapsed: date.timeIntervalSince(startDate ?? date), duration: duration)
  }
}
