// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 14/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreGraphics

/// Defines the perspective projection used to render a crawl plane.
///
/// The value is internal because it supports the package's development
/// previews; the public view presents the established cinematic treatment.
struct StarWarsCrawlCamera {
  /// The rotation of the text plane away from the viewer.
  var tiltDegrees: Double

  /// The strength of the 3D perspective projection.
  var perspective: CGFloat

  /// The widest untransformed text column that the camera can present.
  var maximumTextWidth: CGFloat

  /// The camera used by the public crawl and as the preview's initial setting.
  static let standard = Self(
    tiltDegrees: 78,
    perspective: 1,
    maximumTextWidth: 380
  )
}
