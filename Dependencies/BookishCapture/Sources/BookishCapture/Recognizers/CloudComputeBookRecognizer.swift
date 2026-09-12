// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Reports the current unavailability of Apple's Private Cloud Compute model.
///
/// This explicit provider prevents a selected cloud-compute workflow from silently falling
/// back to on-device Apple Intelligence or OpenAI.
public struct CloudComputeBookRecognizer: BookRecognizer {
  /// The stable identifier for the Cloud Compute recognizer.
  public let id = "com.elegantchaos.bookish.recognizer.cloud"

  /// The user-facing recognizer name.
  public let label = "Cloud Compute"

  /// Explains why the recognizer is unavailable.
  public let description = "Private Cloud Compute is unavailable in this build."

  /// Creates the unavailable recognizer.
  public init() {}

  /// Explains why this build cannot make the requested Private Cloud Compute call.
  public func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate] {
    throw BookRecognitionError.privateCloudComputeUnavailable
  }
}
