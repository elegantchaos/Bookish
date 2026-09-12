// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Reports that this build cannot yet send an image directly to Apple's Foundation Model.
///
/// Direct image input is intentionally separate from OCR so selecting On Device never silently
/// changes the image-processing path. The installed SDK lacks the required image attachment API.
public struct OnDeviceBookRecognizer: BookRecognizer {
  public let id = "com.elegantchaos.bookish.recognizer.direct"
  
  public let label = "On Device"
  
  /// Creates the explicit unavailable service.
  public init() {
  }

  /// Explains why this build cannot make the requested direct-image call.
  public func identifyBooks(in _: Data) async throws -> [BookRecognitionCandidate] {
    throw BookRecognitionError.directImageRecognitionUnavailable
  }
}
