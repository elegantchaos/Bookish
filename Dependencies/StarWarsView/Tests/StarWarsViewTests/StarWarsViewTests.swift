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
  func crawlMotionStartsWithTheEntireTextPlaneBelowTheViewport() {
    let motion = CrawlMotion(
      elapsed: 0,
      duration: 40,
      viewportHeight: 800,
      contentHeight: 1_200
    )

    #expect(motion.progress == 0)
    #expect(motion.verticalOffset == 2_000)
    #expect(!motion.isComplete)
  }

  @Test
  func crawlMotionMovesTheEntireTextPlaneBeyondTheViewport() {
    let motion = CrawlMotion(
      elapsed: 40,
      duration: 40,
      viewportHeight: 800,
      contentHeight: 1_200
    )

    #expect(motion.progress == 1)
    #expect(motion.verticalOffset == -1_400)
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
