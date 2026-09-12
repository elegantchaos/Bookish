// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Reports the current unavailability of direct-image Foundation Models recognition.
///
/// Direct image input remains separate from OCR so selecting On Device never changes the
/// image-processing path implicitly.
public struct OnDeviceBookRecognizer: BookRecognizer {
  /// The stable identifier for the direct-image recognizer.
  public let id = "com.elegantchaos.bookish.recognizer.direct"

  /// The user-facing recognizer name.
  public let label = "On Device"

  /// Explains why the recognizer is unavailable.
  public let description = "Direct on-device image recognition is unavailable in this build."

  /// Creates the unavailable recognizer.
  public init() {}

  /// Explains why this build cannot make the requested direct-image call.
  public func identifyBooks(in _: Data) async throws -> [BookRecognitionCandidate] {
    throw BookRecognitionError.directImageRecognitionUnavailable
  }
}
