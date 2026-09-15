// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import FoundationModels

/// Identifies books by passing an image to Apple's Private Cloud Compute model.
///
/// This explicit provider never falls back to on-device Apple Intelligence or OpenAI.
public struct CloudComputeBookRecognizer: BookRecognizer {
  /// The stable identifier for the Cloud Compute recognizer.
  public let id = "com.elegantchaos.bookish.recognizer.cloud"

  /// The user-facing recognizer name.
  public let label = "Cloud Compute"

  /// Explains the recognizer's cloud-compute processing path.
  public let description =
    "Private Cloud Compute identifies books directly from the selected image."

  /// Indicates whether this direct-image recognizer is available on the current platform.
  public var isSupported: Bool {
    if #available(iOS 27.0, macOS 27.0, *) {
      true
    } else {
      false
    }
  }

  /// Creates the cloud-compute recognizer.
  public init() {}

  /// Identifies books directly from the supplied image on macOS and iOS 27 or later.
  public func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate] {
    guard #available(iOS 27.0, macOS 27.0, *) else {
      throw BookRecognitionError.privateCloudComputeUnavailable
    }

    let model = PrivateCloudComputeLanguageModel()
    guard model.isAvailable else {
      throw BookRecognitionError.privateCloudComputeUnavailable
    }
    return try await DirectImageBookRecognizer().identifyBooks(in: imageData, using: model)
  }
}
