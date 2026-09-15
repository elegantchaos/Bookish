// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCapture
import Foundation

/// Loads the shelf image bundled with Bookish for recognition demonstrations.
enum CaptureGoodExample {
  /// Loads the bundled image data.
  static func load() throws -> Data {
    guard
      let url = Bundle.module.url(
        forResource: "CaptureGoodExample",
        withExtension: "JPG"
      )
    else {
      throw BookRecognitionError.captureGoodExampleUnavailable
    }

    do {
      return try Data(contentsOf: url)
    } catch {
      throw BookRecognitionError.captureGoodExampleUnavailable
    }
  }
}
