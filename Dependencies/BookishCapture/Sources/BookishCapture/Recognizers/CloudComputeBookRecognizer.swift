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
  public let id = BookRecognizerID.foundationInCloud

  /// The user-facing recognizer name.
  public let label = "Cloud Compute"

  /// Explains the recognizer's cloud-compute processing path.
  public let description =
    "Books are identified using Apple's Private Cloud Compute."

  /// Indicates whether this direct-image recognizer is available on the current platform.
  public var isSupported: Bool {
    if #available(iOS 27.0, macOS 27.0, *) {
      (model as? PrivateCloudComputeLanguageModel)?.isAvailable ?? false
    } else {
      false
    }
  }

  /// Model we will use.
  /// Type erased so that we can build on macOS/iOS 26.0
  private var model: Sendable? = nil
  
  /// Creates the cloud-compute recognizer.
  public init() {
    if #available(iOS 27.0, macOS 27.0, *) {
      model = PrivateCloudComputeLanguageModel()
    }
  }

  /// Identifies books directly from the supplied image on macOS and iOS 27 or later.
  public func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate] {
    guard #available(iOS 27.0, macOS 27.0, *) else {
      throw BookRecognitionError.privateCloudComputeUnavailable
    }

    guard let model = model as? PrivateCloudComputeLanguageModel, model.isAvailable else {
      throw BookRecognitionError.privateCloudComputeUnavailable
    }
    
    return try await DirectImageBookRecognizer.identifyBooks(in: imageData, using: model)
  }
}
