// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreGraphics
import Foundation

/// Describes the visual state of one point in a crawl animation.
///
/// Keeping the timing and geometry separate from the view makes the motion
/// predictable and allows the crawl to travel far enough for any text length.
struct CrawlMotion {
  /// The normalized progress through the animation.
  let progress: CGFloat

  /// The vertical displacement of the text from its untransformed position.
  let verticalOffset: CGFloat

  /// Whether the crawl has reached its final visual state.
  let isComplete: Bool

  /// Creates a visual state for an elapsed animation interval and measured layout.
  init(
    elapsed: TimeInterval,
    duration: TimeInterval,
    viewportHeight: CGFloat,
    contentHeight: CGFloat
  ) {
    precondition(duration > 0, "The crawl duration must be greater than zero.")

    let clampedProgress = Self.progress(elapsed: elapsed, duration: duration)
    let viewportHeight = max(viewportHeight, 0)
    let contentHeight = max(contentHeight, 0)
    let startingOffset = viewportHeight + contentHeight
    let endingOffset = -(contentHeight + viewportHeight * 0.25)

    progress = clampedProgress
    verticalOffset = startingOffset + (endingOffset - startingOffset) * clampedProgress
    isComplete = clampedProgress == 1
  }

  /// Clamps an elapsed interval to a normalized animation position.
  static func progress(elapsed: TimeInterval, duration: TimeInterval) -> CGFloat {
    precondition(duration > 0, "The crawl duration must be greater than zero.")

    return CGFloat(min(max(elapsed / duration, 0), 1))
  }
}
