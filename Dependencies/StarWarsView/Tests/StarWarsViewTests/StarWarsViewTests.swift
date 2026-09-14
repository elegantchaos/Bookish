// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreGraphics
import Foundation
import Testing

@testable import StarWarsView

struct StarWarsViewTests {
  @Test
  func crawlMotionStartsBelowTheViewportAtFullScale() {
    let motion = CrawlMotion(
      elapsed: 0,
      duration: 40,
      viewportHeight: 800,
      contentHeight: 1_200
    )

    #expect(motion.progress == 0)
    #expect(motion.verticalOffset == 600)
    #expect(motion.scale == 1)
    #expect(motion.isComplete == false)
  }

  @Test
  func crawlMotionEndsAboveTheViewportAtItsDistantScale() {
    let motion = CrawlMotion(
      elapsed: 40,
      duration: 40,
      viewportHeight: 800,
      contentHeight: 1_200
    )

    #expect(motion.progress == 1)
    #expect(abs(motion.verticalOffset + 416) < 0.000_1)
    #expect(abs(motion.scale - 0.18) < 0.000_1)
    #expect(motion.isComplete)
  }

  @Test(arguments: [-10.0, 80.0])
  func crawlMotionClampsElapsedTimeToItsAnimationRange(elapsed: TimeInterval) {
    let motion = CrawlMotion(
      elapsed: elapsed,
      duration: 40,
      viewportHeight: 800,
      contentHeight: 1_200
    )

    #expect((0...1).contains(motion.progress))
  }
}
