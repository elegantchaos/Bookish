// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Reports that this build cannot yet create Apple's Private Cloud Compute model.
///
/// Private Cloud Compute is a newer beta API than the Foundation Models SDK used by this
/// project. Keeping this explicit provider prevents a silent fallback to either on-device
/// Apple Intelligence or OpenAI.
public struct CloudComputeBookRecognizer: BookRecognizer {
  public let id = "com.elegantchaos.bookish.recognizer.cloud"
  
  public let label = "Cloud Compute"
  
  public let description: String = "Private Cloud Compute is unavailable in this build until its newer Foundation Models SDK and entitlement are available."
  
  /// Creates the explicit unavailable service.
  public init() {
  }

  /// Explains why this build cannot make the requested Private Cloud Compute call.
  public func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate] {
    throw BookRecognitionError.privateCloudComputeUnavailable
  }
}
